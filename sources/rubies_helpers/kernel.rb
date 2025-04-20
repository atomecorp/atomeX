
# websocket_bridge.rb
# Ruby WASM bridge to JavaScript WebSocket client
# Include this in your Ruby WASM application to communicate with the WebSocket server

module WebSocket
  class Bridge
    def initialize
      @channels = {}
    end

    # Register a channel and return a channel object for method chaining
    def register_channel(channel_name)
      unless @channels[channel_name]
        @channels[channel_name] = Channel.new(self, channel_name)
        js_register_channel(channel_name)
      end

      @channels[channel_name]
    end

    # Send a message to a specific channel
    def send(channel, action, payload = nil)
      payload_json = payload.nil? ? 'null' : payload.to_json
      js_code = "window.wsClient.send('#{channel}', '#{action}', #{payload_json})"
      js_eval(js_code)
    end

    # Register a handler for a specific channel and action
    def on(channel, action, &block)
      return unless block_given?

      @channels[channel] ||= Channel.new(self, channel)
      @channels[channel].on(action, &block)
    end

    private

    # Register a channel with the JavaScript client
    def js_register_channel(channel_name)
      js_code = "window.wsClient.registerChannel('#{channel_name}')"
      js_eval(js_code)
    end

    # Evaluate JavaScript code - this would be implemented differently
    # depending on your Ruby WASM setup (Opal, etc.)
    def js_eval(code)
      # In Opal, you would use:
      # `#{code}`

      # In other Ruby WASM implementations, you might use something else
      # This is a placeholder for your actual JS evaluation mechanism
      puts "JS EVAL: #{code}"
    end
  end

  # Channel class for easier API
  class Channel
    def initialize(bridge, name)
      @bridge = bridge
      @name = name
      @handlers = {}
    end

    # Register a handler for an action
    def on(action, &block)
      @handlers[action] = block if block_given?
      self
    end

    # Send a message to this channel
    def send(action, payload = nil)
      @bridge.send(@name, action, payload)
    end

    # Call a handler (should be called from the JS bridge)
    def handle_action(action, payload)
      @handlers[action]&.call(payload)
    end
  end

  # Create and return a singleton instance
  def self.client
    @client ||= Bridge.new
  end

  # Helper method to get a channel directly
  def self.channel(name)
    client.register_channel(name)
  end
end

# Example usage:
#
# # Register the hot reload channel (not needed for basic functionality)
# hot_reload = WebSocket.channel('hot_reload')
#
# # Or use it directly within your application
# WebSocket.client.on('app_channel', 'message') do |payload|
#   puts "Received message: #{payload}"
# end
#
# # Send a message
# WebSocket.client.send('app_channel', 'update', { data: 'example' })