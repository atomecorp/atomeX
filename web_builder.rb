#!/usr/bin/env ruby

# Builder script for Opal and WASM compilation
# This script handles the compilation of Ruby applications to JavaScript (via Opal)
# and WebAssembly (WASM), with options to skip either compilation step.

require 'fileutils'
require 'open-uri'

class BuilderScript
  # Constants for WASM URLs
  # RUBY_WASM_URL: Contains the main Ruby interpreter compiled to WebAssembly.
  # This archive provides the core Ruby binary that will be used to execute Ruby code in the browser.
  RUBY_WASM_URL = "https://github.com/ruby/ruby.wasm/releases/latest/download/ruby-3.4-wasm32-unknown-wasip1-full.tar.gz"

  # RUBY_WASI_TGZ_URL: Contains WASI (WebAssembly System Interface) components and additional libraries.
  # These are required runtime dependencies that allow the Ruby WASM binary to interact with the system
  # environment and provide standard library features within the browser.
  RUBY_WASI_TGZ_URL = "https://github.com/ruby/ruby.wasm/releases/download/2.7.1/ruby-3.4-wasm-wasi-2.7.1.tgz"

  def initialize(*args)
    # Parse command line options
    @production = args.include?(:production)
    # Initialize build paths
    @build_dir = "build"
    @opal_dir = "#{@build_dir}/opal"
    @wasm_dir = "#{@build_dir}/wasm"

    # Extract version and file information from URLs
    parse_wasm_urls
  end

  # Extract version and path information from the WASM URLs
  def parse_wasm_urls
    # Extract the filename from the WASM URL
    @ruby_wasm_filename = File.basename(RUBY_WASM_URL)

    # Extract the directory name (without the archive extension)
    # Handle various archive extensions (.tar.gz, .tgz, etc.)
    @ruby_wasm_dirname = @ruby_wasm_filename.sub(/\.(tar\.gz|tgz|tar)$/, '')

    # Set a default Ruby version if we can't extract it
    begin
      if @ruby_wasm_dirname =~ /ruby-(\d+\.\d+)/
        @ruby_wasm_version = $1
      else
        @ruby_wasm_version = "3.4" # Default version
      end
    rescue
      @ruby_wasm_version = "3.4" # Default version
    end

    # Extract the filename from the WASI URL
    @ruby_wasi_filename = File.basename(RUBY_WASI_TGZ_URL)

    # Try to extract version information, but use defaults if pattern doesn't match
    begin
      if @ruby_wasi_filename =~ /ruby-\d+\.\d+-wasm-wasi-(\d+\.\d+\.\d+)/
        @ruby_wasi_version = $1
      else
        @ruby_wasi_version = "2.7.1" # Default version
      end
    rescue
      @ruby_wasi_version = "2.7.1" # Default version
    end

    puts "Using Ruby WASM filename: #{@ruby_wasm_filename}, extracted directory: #{@ruby_wasm_dirname}"
    puts "Using Ruby WASI filename: #{@ruby_wasi_filename}"
  end

  # Main execution method
  def run
    # Install dependencies if needed
    install_dependencies

    # Create build directories
    create_build_directories

    # Run Opal compilation unless skipped
    compile_opal(true)

    # Run WASM compilation unless skipped
    compile_wasm

    # Display usage instructions
    show_usage_instructions
  end

  # Create the necessary build directories
  def create_build_directories
    FileUtils.mkdir_p(@opal_dir)
    FileUtils.mkdir_p(@wasm_dir)
  end

  # Install dependencies using Bundler
  def install_dependencies
    system("bundle install") unless File.exist?("Gemfile.lock")

    if @update_mode
      puts "Forcing update of all gems via bundler..."
      system("bundle update")
    else
      puts "Gem update skipped (option --update not used)."
    end
  end

  # Add <script> tags dynamically to an HTML file
  def add_script_tag_to_index(name, files, ruby_type=nil)
    file_path = "build/index_#{name}.html"
    tags = []

    files.each do |file|
      if ruby_type
        type = "type='text/ruby'"
        options = "data-eval='async'"
      else
        type = ''
        options = "defer"
      end
      tags << "<script #{type} src='#{file}' #{options}></script>"
    end
    scripts_to_add = tags.join("\n")

    content = File.read(file_path)

    if content.include?('</body>')
      modified_content = content.gsub('</body>', "</body>\n#{scripts_to_add}")
      File.open(file_path, 'w') { |file| file.write(modified_content) }
      puts "Scripts have been successfully added after </body>."
    else
      puts "Error: </body> tag not found in the file."
    end
  end

  # Compile the Ruby application with Opal
  def compile_opal(build_mode=false)
    puts "\n== Compiling with Opal =="
    tag_content = []

    # Compile Opal initializer
    opal_compiler("specific/opal/opal_init.rb", true)
    tag_content << "./opal/opal_init.js"

    # Compile all source files
    Dir.entries('./sources').each do |file|
      next if file.start_with?('.')
      opal_compiler("sources/#{file}")
      tag_content << "./opal/#{File.basename(file, ".*")}.js"
    end

    # Copy app directory
    copy_app_directory

    # Compile application entry point
    opal_compiler("app/index.rb")
    tag_content << "./opal/index.js"
    if build_mode
      # Add script tags to HTML
      add_script_tag_to_index(:opal, tag_content)
    end

  end

  # Compile a Ruby file with Opal
  def opal_compiler(file, add_opal = false)
    debug = @production ? '' : '--enable-source-location '

    if add_opal
      opal_cmd = "cat #{file} | bundle exec opal -r opal-parser --compile #{debug} - > #{@opal_dir}/#{File.basename(file, ".*")}.js"
    else
      opal_cmd = "cat #{file} | bundle exec opal --no-opal --compile #{debug} - > #{@opal_dir}/#{File.basename(file, ".*")}.js"
    end

    system(opal_cmd)
  end

  # Copy the app directory to build directory
  def copy_app_directory
    build_app_dir = "#{@build_dir}/app"
    FileUtils.mkdir_p(build_app_dir) unless Dir.exist?(build_app_dir)
    FileUtils.cp_r(Dir.glob("app/*"), build_app_dir)
  end

  # Compile the Ruby application with WASM
  def compile_wasm
    puts "\n== Compiling with Ruby WASM =="

    # Download or update Ruby WASM files
    process_ruby_wasm
    process_ruby_wasi_tgz

    # Compile the app to WASM
    compile_app_to_wasm

    # Modify JS files generated by WASM
    modify_wasm_js_files

    tag_content = []
    tag_content << "./specific/wasm/wasm_init.rb"

    Dir.entries('./sources').each do |file|
      next if file.start_with?('.')
      tag_content << "./sources/#{file}"
    end

    tag_content << "./app/index.rb"
    add_script_tag_to_index(:wasm, tag_content, :ruby)
  end

  # Download and extract Ruby WASM
  def process_ruby_wasm
    ruby_wasm_dest = "#{@wasm_dir}/ruby.wasm"

    if @update_mode && File.exist?(ruby_wasm_dest)
      puts "Option --update enabled, deleting existing file #{ruby_wasm_dest}..."
      File.delete(ruby_wasm_dest)
    end

    unless File.exist?(ruby_wasm_dest)
      wasm_archive = "#{@wasm_dir}/#{@ruby_wasm_filename}"
      download_and_extract_wasm(RUBY_WASM_URL, wasm_archive, ruby_wasm_dest)
    else
      puts "Ruby WASM file already exists, skipping download."
    end
  end

  # Download and extract a WASM archive
  def download_and_extract_wasm(url, archive_path, dest_path)
    puts "Downloading Ruby WASM from #{url}..."
    FileUtils.mkdir_p(File.dirname(archive_path))
    download_file(url, archive_path)

    puts "Extracting #{archive_path}..."

    # Handle different archive types
    extract_cmd = case archive_path
                  when /\.tar\.gz$/, /\.tgz$/
                    "tar xfz #{archive_path} -C #{@wasm_dir}"
                  when /\.tar$/
                    "tar xf #{archive_path} -C #{@wasm_dir}"
                  when /\.zip$/
                    "unzip #{archive_path} -d #{@wasm_dir}"
                  else
                    # Default to tar.gz
                    "tar xfz #{archive_path} -C #{@wasm_dir}"
                  end

    system(extract_cmd)

    FileUtils.mkdir_p(File.dirname(dest_path))

    # Try multiple common paths for finding the ruby binary
    possible_paths = [
      "#{@wasm_dir}/#{@ruby_wasm_dirname}/usr/local/bin/ruby",
      "#{@wasm_dir}/#{@ruby_wasm_dirname}/bin/ruby",
      "#{@wasm_dir}/usr/local/bin/ruby",
      "#{@wasm_dir}/bin/ruby"
    ]

    ruby_binary_path = possible_paths.find { |path| File.exist?(path) }

    if ruby_binary_path
      FileUtils.mv(ruby_binary_path, dest_path)
      puts "Ruby WASM found at #{ruby_binary_path} and moved to #{dest_path}"
    else
      puts "Warning: Ruby binary not found at any expected paths"
      puts "Searching for ruby binary in extracted directory..."

      # Attempt to find the ruby binary in the extracted directory
      ruby_binary = Dir.glob("#{@wasm_dir}/**/bin/ruby").first
      if ruby_binary
        FileUtils.mv(ruby_binary, dest_path)
        puts "Ruby WASM found at #{ruby_binary} and moved to #{dest_path}"
      else
        abort("Error: Ruby binary not found in extracted archive.")
      end
    end
  end

  # Download and extract Ruby WASI TGZ
  def process_ruby_wasi_tgz
    wasi_tgz = "#{@wasm_dir}/#{@ruby_wasi_filename}"

    if @update_mode && File.exist?(wasi_tgz)
      puts "Option --update enabled, deleting existing file #{wasi_tgz}..."
      File.delete(wasi_tgz)
    end

    unless File.exist?(wasi_tgz)
      download_and_extract_wasi_tgz(RUBY_WASI_TGZ_URL, wasi_tgz)
    else
      puts "#{@ruby_wasi_filename} already exists, skipping download."
    end
  end

  # Download and extract a WASI TGZ archive
  def download_and_extract_wasi_tgz(url, tgz_path)
    puts "Downloading #{@ruby_wasi_filename} from #{url}..."
    FileUtils.mkdir_p(File.dirname(tgz_path))
    download_file(url, tgz_path)

    puts "Extracting #{tgz_path}..."

    # Handle different archive types
    extract_cmd = case tgz_path
                  when /\.tar\.gz$/, /\.tgz$/
                    "tar xfz #{tgz_path} -C #{@wasm_dir}"
                  when /\.tar$/
                    "tar xf #{tgz_path} -C #{@wasm_dir}"
                  when /\.zip$/
                    "unzip #{tgz_path} -d #{@wasm_dir}"
                  else
                    # Default to tar.gz
                    "tar xfz #{tgz_path} -C #{@wasm_dir}"
                  end

    system(extract_cmd)
    puts "#{@ruby_wasi_filename} downloaded and extracted in the #{@wasm_dir} directory."
  end

  # Compile the Ruby runtime to WASM
  def compile_app_to_wasm
    puts "Compiling Ruby runtime to WebAssembly..."
    output_path = "#{@wasm_dir}/ruby_runtime.wasm"

    # Find the usr directory path to use in compilation
    usr_dirs = [
      "#{@wasm_dir}/#{@ruby_wasm_dirname}/usr",
      "#{@wasm_dir}/usr",
      Dir.glob("#{@wasm_dir}/**/usr").first
    ].compact

    usr_dir = usr_dirs.find { |dir| Dir.exist?(dir) }

    if usr_dir.nil?
      puts "Warning: Could not find usr directory in extracted archive."
      puts "Trying to compile without specifying usr directory..."

      wasm_compile_cmd = "bundle exec rbwasm pack #{@wasm_dir}/ruby.wasm -o #{output_path}"
    else
      puts "Found usr directory at: #{usr_dir}"
      wasm_compile_cmd = "bundle exec rbwasm pack #{@wasm_dir}/ruby.wasm " +
        "--dir ./#{usr_dir}::/usr " +
        "-o #{output_path}"
    end

    puts "Executing: #{wasm_compile_cmd}"
    system(wasm_compile_cmd)

    if $?.exitstatus == 0
      puts "Ruby runtime successfully compiled to #{output_path}"
    else
      puts "Error during Ruby runtime WASM compilation with usr directory."

      if usr_dir
        puts "Trying alternative compilation without usr directory..."
        alt_cmd = "bundle exec rbwasm pack #{@wasm_dir}/ruby.wasm -o #{output_path}"
        puts "Executing: #{alt_cmd}"
        system(alt_cmd)

        if $?.exitstatus == 0
          puts "Ruby runtime successfully compiled to #{output_path} using alternative method"
        else
          abort("Error during Ruby runtime WASM compilation using both methods.")
        end
      else
        abort("Error during Ruby runtime WASM compilation.")
      end
    end
  end

  # Modify the generated JS files from WASM
  def modify_wasm_js_files
    package_dist_dir = "#{@wasm_dir}/package/dist"
    iife_js_file_path = "#{package_dist_dir}/browser.script.iife.js"
    umd_js_file_path = "#{package_dist_dir}/browser.script.umd.js"

    FileUtils.mkdir_p(File.dirname(iife_js_file_path))
    FileUtils.mkdir_p(File.dirname(umd_js_file_path))

    modify_js_file(iife_js_file_path, /const response = fetch\(`https:\/\/cdn.*?ruby\+stdlib\.wasm`\);/, 'const response = fetch(`./wasm/package/dist/ruby+stdlib.wasm`);')
    modify_js_file(umd_js_file_path, /const response = fetch\(`https:\/\/cdn.*?ruby\+stdlib\.wasm`\);/, 'const response = fetch(`./wasm/package/dist/ruby+stdlib.wasm`);')
  end

  # Modify a JS file with a specific pattern
  def modify_js_file(file_path, pattern, replacement)
    if File.exist?(file_path)
      puts "Modifying JavaScript file #{file_path}..."
      content = File.read(file_path)
      new_content = content.gsub(pattern, replacement)
      File.write(file_path, new_content)
      puts "JavaScript file #{file_path} modified successfully!"
    else
      puts "Warning: JavaScript file #{file_path} not found. Check if WASM compilation generated the expected files."
    end
  end

  # Display usage instructions
  def show_usage_instructions
    puts "\n== Usage Instructions =="
    puts "To use the Opal version: open #{@build_dir}/index_opal.html in your browser."
    puts "To use the WASM version: open #{@build_dir}/index_wasm.html in your browser."
  end

  # Download a remote file
  def download_file(url, destination)
    URI.open(url) do |remote|
      File.open(destination, "wb") { |file| file.write(remote.read) }
    end
  end

  # Replace the index.html based on the desired mode
  def wanted_mode(mode)
    puts "wanted mode is #{mode}"
    source_file = "build/index_#{mode}.html"
    destination_file = 'build/index.html'

    begin
      content = File.read(source_file)
      File.write(destination_file, content)
      puts "Successfully copied #{source_file} to #{destination_file}"
    rescue Errno::ENOENT => e
      puts "Error: #{e.message}"
      puts "Make sure the source file #{source_file} exists and the build directory is present."
    rescue => e
      puts "An unexpected error occurred: #{e.message}"
    end
  end
end