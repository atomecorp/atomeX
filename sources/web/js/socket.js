export function connectWebSocket() {
	const wsUrl = `ws://${window.location.hostname}:3000/ws`;
	const log = (msg, data) => console.log(`Hot Reload: ${msg}`, data || '');

	log('Connecting to', wsUrl);

	const ws = new WebSocket(wsUrl);

	ws.onopen = () => log('WebSocket connected');
	ws.onmessage = (event) => {
		log('Message received:', event.data);
		if (event.data === 'reload') {
			log('Reloading page...');
			window.location.reload();
		}
	};
	ws.onclose = () => {
		log('WebSocket disconnected, retrying...');
		setTimeout(connectWebSocket, 1000);
	};
	ws.onerror = (error) => {
		console.error('Hot Reload: WebSocket error:', error);
	};
}