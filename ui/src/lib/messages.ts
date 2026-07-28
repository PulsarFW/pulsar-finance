// central NUI message router, forwards SendNUIMessage calls from client.lua/components/banking/atms.lua to the finance store

import { handleFinanceMessage } from './store/finance.svelte';

interface InboundMessage {
	type?: string;
	data?: unknown;
}

function route(type: string, data: unknown) {
	const record = (data ?? {}) as Record<string, unknown>;
	handleFinanceMessage(type, record);
}

/** Returns an unsubscribe function */
export function attachMessageListener(): () => void {
	const handler = (event: MessageEvent<InboundMessage>) => {
		if (!event.isTrusted) return;
		if (event.data?.type) route(event.data.type, event.data.data);
	};
	window.addEventListener('message', handler);
	return () => window.removeEventListener('message', handler);
}

export { route as applyMessage };
