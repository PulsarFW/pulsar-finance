import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';

// base MUST stay relative — FiveM's NUI loads this over a local nui:// scheme,
// not from a domain root, so absolute "/assets/..." paths would 404 in-game.
export default defineConfig({
	base: './',
	plugins: [svelte()],
	build: {
		outDir: 'dist',
		emptyOutDir: true,
	},
});
