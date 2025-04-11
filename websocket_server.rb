# websocket_server.rb
# Modular WebSocket server for hot reloading and other functionalities

require 'em-websocket'
require 'eventmachine'
require 'json'
require 'logger'

class WebSocketServer
  attr_reader :channels, :clients, :logger

  def initialize(host: '0.0.0.0', port: 8088, log_level: Logger::INFO)
    @host = host
    @port = port
    @clients = []
    @channels = {}
    @logger = Logger.new(STDOUT)
    @logger.level = log_level

    # Register default channels
    register_channel('hot_reload', HotReloadChannel.new(self))

    @logger.info("WebSocket server initialized on #{@host}:#{@port}")
  end

  def start
    Thread.new do
      EventMachine.run do
        @logger.info("Starting WebSocket server on #{@host}:#{@port}")

        EventMachine::WebSocket.start(host: @host, port: @port) do |ws|
          ws.onopen do
            @logger.info("Client connected")
            client = Client.new(ws, self)
            @clients << client
          end

          ws.onmessage do |msg|
            begin
              data = JSON.parse(msg)
              channel_name = data['channel']
              action = data['action']
              payload = data['payload']

              client = find_client(ws)

              if channel_name && action
                handle_message(client, channel_name, action, payload)
              else
                @logger.warn("Received message with invalid format: #{msg}")
              end
            rescue JSON::ParserError => e
              @logger.error("Failed to parse message: #{e.message}")
            end
          end

          ws.onclose do
            @logger.info("Client disconnected")
            client = find_client(ws)
            @clients.delete(client) if client
          end

          ws.onerror do |error|
            @logger.error("WebSocket error: #{error.message}")
          end
        end
      end
    end
  end

  def register_channel(name, channel)
    @channels[name] = channel
    @logger.info("Registered channel: #{name}")
  end

  def handle_message(client, channel_name, action, payload)
    if @channels.key?(channel_name)
      @channels[channel_name].handle_action(client, action, payload)
    else
      @logger.warn("Received message for unknown channel: #{channel_name}")
    end
  end

  def broadcast(channel_name, action, payload = nil)
    message = {
      channel: channel_name,
      action: action,
      payload: payload
    }.to_json

    @logger.debug("Broadcasting to channel '#{channel_name}': #{action}")
    @clients.each do |client|
      client.send(message)
    end
  end

  def find_client(websocket)
    @clients.find { |client| client.websocket == websocket }
  end
end

# Base class for all channels
class Channel
  attr_reader :server

  def initialize(server)
    @server = server
  end

  def handle_action(client, action, payload)
    method_name = "handle_#{action}"
    if respond_to?(method_name)
      send(method_name, client, payload)
    else
      server.logger.warn("Unknown action '#{action}' for channel #{self.class}")
    end
  end
end

# Hot Reload specific channel
class HotReloadChannel < Channel
  def initialize(server)
    super(server)
    server.logger.info("HotReloadChannel initialized")
  end

  def trigger_reload(file_path = nil)
    payload = file_path ? { file: file_path } : nil
    server.broadcast('hot_reload', 'reload', payload)
    server.logger.info("Hot reload triggered" + (file_path ? " for file: #{file_path}" : ""))
  end

  def handle_subscribe(client, _payload)
    server.logger.info("Client subscribed to hot_reload channel")
    # You could add client to a specific subscribers list if needed
  end
end

# Client representation
class Client
  attr_reader :websocket, :server, :id

  def initialize(websocket, server)
    @websocket = websocket
    @server = server
    @id = generate_id
  end

  def send(message)
    @websocket.send(message)
  end

  private

  def generate_id
    "client_#{Time.now.to_i}_#{rand(1000)}"
  end
end

# This allows you to run the server standalone if needed
if __FILE__ == $0
  server = WebSocketServer.new
  server.start
  puts "WebSocket server started. Press Ctrl+C to stop."
  loop do
    sleep 1
  end
end