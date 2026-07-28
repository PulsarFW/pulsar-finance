// dev-only simulated Lua message stream, SET_APP + character SET_DATA. Bank/Crypto/Loans list data pulls through
// NUI-callback responses (nui.ts, mockData.ts) rather than push messages, so it doesn't need simulating here
// query params preview any brand/app combo, e.g. ?brand=maze or ?app=ATM&brand=ud

import { applyMessage } from './messages';
import type { AppMode, Brand } from '../config';

export function startMock(): void {
	const params = new URLSearchParams(window.location.search);
	const brand = (params.get('brand') as Brand) || 'fleeca';
	const app = (params.get('app') as AppMode) || 'BANK';

	setTimeout(() => {
		applyMessage('SET_DATA', { type: 'character', data: { ID: 1, SID: 1, First: 'John', Last: 'Doe', Cash: 2450 } });
		applyMessage('SET_APP', { brand, app });
	}, 200);
}
