# builder.rb
# Main script that orchestrates the build and deployment process

require 'fileutils'
require './web_builder.rb'

# Define file names
html_builder = "html_builder.rb"
# web_builder = "web_builder.rb"
hot_reloader = "hot_reloader.rb"

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

# Start the hot reloader
exec("ruby #{hot_reloader}")