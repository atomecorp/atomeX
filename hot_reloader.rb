# hot_reloader.rb
# File watcher with WebSocket integration for hot reloading

require 'listen'
require 'fileutils'
require './web_builder.rb'
require './websocket_server.rb'

# Initialize the WebSocket server
begin
  puts "Starting WebSocket server..."
  websocket_server = WebSocketServer.new
  websocket_server.start
  # Attendre un peu pour s'assurer que le serveur démarre
  sleep 1
  puts "WebSocket server started successfully on port 8088"
rescue => e
  puts "ERROR: Failed to start WebSocket server: #{e.message}"
  puts e.backtrace.join("\n")
end

# Get the hot reload channel
hot_reload_channel = websocket_server.channels['hot_reload']

puts "💻 Starting hot reload system with WebSocket server..."

# Main file watcher for app directory
app_listener = Listen.to('app/') do |modified, added, removed|
  unless (modified + added + removed).empty?
    modified.each do |file|
      filename = File.basename(file)
      puts "Modified: #{filename}"
    end

    # Rebuild the application
    puts "🔨 Rebuilding application..."
    builder = BuilderScript.new
    builder.copy_app_directory
    builder.compile_opal

    # Trigger browser refresh
    hot_reload_channel.trigger_reload
  end
end

# Additional watchers
sources_listener = Listen.to('sources/') do |modified, added, removed|
  unless (modified + added + removed).empty?
    modified.each do |file|
      filename = File.basename(file)
      puts "Modified in sources/: #{filename}"
    end

    # Trigger browser refresh for source changes
    hot_reload_channel.trigger_reload
  end
end

html_listener = Listen.to('html_sources/') do |modified, added, removed|
  unless (modified + added + removed).empty?
    modified.each do |file|
      filename = File.basename(file)
      puts "Modified in html_sources/: #{filename}"
    end

    # Trigger browser refresh for HTML changes
    hot_reload_channel.trigger_reload
  end
end

# Start all listeners
puts "👂 Watching directories for hot reload with WebSocket..."
app_listener.start
sources_listener.start
html_listener.start

puts "🔥 Hot reloader is running. Press Ctrl+C to stop."

# Keep the script running
begin
  sleep
rescue Interrupt
  puts "\n🛑 Stopping hot reloader..."
end