import { mount } from 'svelte';
import App from './App.svelte';
import './theme.css';

const target = document.getElementById('app');
if (!target) {
	throw new Error('#app mount node not found');
}

const app = mount(App, { target });

if (import.meta.env.DEV) {
	// Simulates SET_APP + SET_DATA so `bun run dev` shows a live panel in a
	// regular browser. Not bundled into production
	import('./lib/mock').then(({ startMock }) => startMock());
}

export default app;
