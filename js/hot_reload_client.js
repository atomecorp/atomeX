/**
 * hot_reload_client.js
 * Client-side WebSocket handler for hot reloading and other functionalities
 *
 * This should be included in your HTML files to enable hot reloading
 */

(function() {
    // WebSocket Client class for modular communication
    class WSClient {
        constructor(options = {}) {
            this.options = Object.assign({
                host: window.location.hostname || 'localhost',
                port: 8088,
                reconnectInterval: 2000,
                debug: false
            }, options);

            this.channels = {};
            this.connected = false;
            this.socket = null;
            this.reconnectTimer = null;

            this.connect();
        }

        connect() {
            const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${wsProtocol}//${this.options.host}:${this.options.port}`;

            this.log(`Connecting to WebSocket server at ${wsUrl}`);

            try {
                this.socket = new WebSocket(wsUrl);

                this.socket.onopen = this.handleOpen.bind(this);
                this.socket.onmessage = this.handleMessage.bind(this);
                this.socket.onclose = this.handleClose.bind(this);
                this.socket.onerror = this.handleError.bind(this);
            } catch (error) {
                this.log('Error creating WebSocket connection:', error);
                this.scheduleReconnect();
            }
        }

        handleOpen() {
            this.connected = true;
            this.log('WebSocket connection established');

            // Subscribe to previously registered channels
            Object.keys(this.channels).forEach(channelName => {
                this.subscribe(channelName);
            });
        }

        handleMessage(event) {
            try {
                const data = JSON.parse(event.data);
                const { channel, action, payload } = data;

                this.log(`Received message: channel=${channel}, action=${action}`);

                if (channel && action && this.channels[channel]) {
                    const handlers = this.channels[channel].handlers || {};

                    if (handlers[action]) {
                        handlers[action](payload);
                    } else {
                        this.log(`No handler for action '${action}' in channel '${channel}'`);
                    }
                }
            } catch (error) {
                this.log('Error handling message:', error);
            }
        }

        handleClose(event) {
            this.connected = false;
            this.log(`WebSocket connection closed: ${event.code} ${event.reason}`);
            this.scheduleReconnect();
        }

        handleError(error) {
            this.log('WebSocket error:', error);
        }

        scheduleReconnect() {
            if (this.reconnectTimer) {
                clearTimeout(this.reconnectTimer);
            }

            this.log(`Scheduling reconnect in ${this.options.reconnectInterval}ms`);

            this.reconnectTimer = setTimeout(() => {
                this.log('Attempting to reconnect...');
                this.connect();
            }, this.options.reconnectInterval);
        }

        registerChannel(channelName, handlers = {}) {
            this.channels[channelName] = { handlers };
            this.log(`Registered channel: ${channelName}`);

            // If already connected, subscribe immediately
            if (this.connected) {
                this.subscribe(channelName);
            }

            return {
                on: (action, handler) => {
                    this.channels[channelName].handlers[action] = handler;
                    return this;
                }
            };
        }

        subscribe(channelName) {
            this.send(channelName, 'subscribe');
        }

        send(channel, action, payload) {
            if (!this.connected) {
                this.log(`Cannot send message: not connected`);
                return false;
            }

            const message = JSON.stringify({
                channel,
                action,
                payload
            });

            try {
                this.socket.send(message);
                return true;
            } catch (error) {
                this.log('Error sending message:', error);
                return false;
            }
        }

        log(...args) {
            if (this.options.debug) {
                console.log('[WSClient]', ...args);
            }
        }
    }

    // Initialize the WebSocket client
    const wsClient = new WSClient({ debug: true });

    // Register hot reload channel and handler
    wsClient.registerChannel('hot_reload')
        .on('reload', (payload) => {
            console.log('🔄 Hot reload triggered, refreshing page...');
            window.location.reload();
        });

    // Expose the client globally for Ruby WASM to use
    window.wsClient = wsClient;

    // Log that hot reload is active
    console.log('🔥 Hot reload client initialized');
})();