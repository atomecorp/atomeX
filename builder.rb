# builder.rb
# Main script that orchestrates the build and deployment process

require 'fileutils'
require './web_builder.rb'
require 'thread'
require 'rbconfig'

# Define file names
html_builder = "html_builder.rb"
hot_reloader = "hot_reloader.rb"

# Helper method to open URL in the default browser based on operating system
def open_browser(url)
  os = RbConfig::CONFIG['host_os']

  command = case os
            when /mswin|mingw|cygwin/i  # Windows
              "start"
            when /darwin/i              # macOS
              "open"
            when /linux|bsd/i           # Linux/BSD
              "xdg-open"
            else
              puts "Unknown operating system. Please open the browser manually at: #{url}"
              return false
            end

  system("#{command} #{url}")
end

# Install dependencies
puts "Installing dependencies..."
system("bundle install")

# Run Ruby scripts
puts "Running #{html_builder}..."
system("ruby #{html_builder}")

# Create the build folder if it doesn't exist
FileUtils.mkdir_p("build")

# Initialize and run the web builder
if ARGV.include? "--production"
  puts "Running in production mode..."
  web_builder = BuilderScript.new(:production)
else
  puts "Running in development mode..."
  web_builder = BuilderScript.new
end

web_builder.run

# Determine the target build mode
if ARGV.include?('--wasm')
  mode = :wasm
elsif ARGV.include?('--opal')
  mode = :opal
else
  mode = :opal
end
web_builder.wanted_mode(mode)

puts "All build scripts have been executed successfully."

# The hot reloader should always run
if ARGV.include?('--launch')
  # Run both the web server and hot reloader in parallel
  threads = []

  # Thread for web server
  threads << Thread.new do
    puts "Starting web server on port 8087..."
    system("cd build && ruby -run -e httpd . -p 8087")
  end

  # Thread for hot reloader
  threads << Thread.new do
    puts "Starting hot reloader..."
    system("ruby #{hot_reloader}")
  end

  # Open browser after a short delay to ensure server has started
  threads << Thread.new do
    puts "Opening browser..."
    sleep 1.5  # Give the server a moment to start
    open_browser("http://127.0.0.1:8087")
  end

  # Wait for threads to finish
  threads.each(&:join)
else
  # Only run the hot reloader (no web server)
  puts "Starting hot reloader only..."
  exec("ruby #{hot_reloader}")
end