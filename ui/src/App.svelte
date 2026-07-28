<!-- escape-key close -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { attachMessageListener } from './lib/messages';
	import { Nui } from './lib/nui';
	import Shell from './lib/Shell.svelte';

	onMount(() => {
		const detachMessages = attachMessageListener();
		const onKey = (e: KeyboardEvent) => {
			if (e.key === 'Escape') Nui.close();
		};
		window.addEventListener('keydown', onKey);
		return () => {
			detachMessages();
			window.removeEventListener('keydown', onKey);
		};
	});
</script>

<main>
	<Shell />
</main>

<style>
	main {
		position: relative;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
	}
</style>
