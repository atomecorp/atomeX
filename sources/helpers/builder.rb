# builder.rb
# Main script that orchestrates the build and deployment process

require 'fileutils'
require './web_builder.rb'
require 'rbconfig'

# Define file names
html_builder = "html_builder.rb"

# Helper method to open URL in the default browser based on operating system
def open_browser(url)
  os = RbConfig::CONFIG['host_os']

  command = case os
            when /mswin|mingw|cygwin/i # Windows
              "start"
            when /darwin/i # macOS
              "open"
            when /linux|bsd/i # Linux/BSD
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
#

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
mode = if ARGV.include?('--wasm')
         :wasm
       elsif ARGV.include?('--opal')
         :opal
       else
         :opal
       end
web_builder.wanted_mode(mode)
open_browser('http://127.0.0.1:3000')
puts "All build scripts have been executed successfully."
if ARGV.include?('--launch')
  native_dir = File.expand_path("../../native", __dir__)
  system("cd #{native_dir} && cargo tauri dev -- -- --no-watch")
end

