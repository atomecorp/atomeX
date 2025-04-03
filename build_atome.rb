# launcher.rb

# This Ruby script launches two other Ruby scripts: html_builder.rb and web_builder.rb

# Define the filenames
html_builder = "html_builder.rb"
web_builder = "web_builder.rb"

# Check if the files exist before running them
unless File.exist?(html_builder)
  puts "Error: #{html_builder} not found."
  exit 1
end

unless File.exist?(web_builder)
  puts "Error: #{web_builder} not found."
  exit 1
end

# Run the Ruby scripts
puts "Running #{html_builder}..."
system("ruby #{html_builder}")

puts "Running #{web_builder}..."
system("ruby #{web_builder}")

puts "Both scripts have been executed successfully."