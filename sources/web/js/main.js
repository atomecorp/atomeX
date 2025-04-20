import { connectWebSocket } from './socket.js';

document.addEventListener('DOMContentLoaded', () => {
    const needSocket = true; // Set to false in production
    const log = message => console.log(message);

    log("Checking Tauri object...");

    if (typeof window.__TAURI__ === 'undefined') {
        log("Error: Tauri object not found");
        setupSimulation();
    } else {
        log("Tauri object found");
        const invoke = window.__TAURI__.tauri?.invoke ||
            window.__TAURI__.invoke ||
            window.__TAURI__.core?.invoke;
        setupTauri(invoke);
    }

    function setupTauri(invokeFunction) {
        log("Configuring with Tauri API...");

        async function invoke(cmd, args) {
            try {
                return await invokeFunction(cmd, args);
            } catch (error) {
                log(`Invoke error (${cmd}): ${error.message}`);
                throw error;
            }
        }

        (async () => {
            try {
                log("Starting Axum server...");
                await invoke('start_axum_server');
                log("Server started successfully");

                if (needSocket) {
                    log('Hot Reload: Script initialized');
                    connectWebSocket();
                }
            } catch (error) {
                log(`Server start error: ${error.message}`);
            }
        })();
    }

    function setupSimulation() {
        log("Simulation mode enabled (no Tauri detected)");

        setTimeout(() => {
            log("Simulated server started successfully");
            if (needSocket) {
                log('Hot Reload: Script initialized');
                connectWebSocket();
            }
        }, 1000);
    }
});

