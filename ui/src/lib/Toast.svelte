<!-- auto-dismisses after 4s, bottom-right placement, store exposes a toast.success/toast.error API (see store/finance.svelte.ts) -->
<script lang="ts">
	import { toastState, dismissToast } from './store/finance.svelte';
	import Icon from './Icon.svelte';
</script>

<div class="stack">
	{#each toastState.toasts as t (t.id)}
		<div class="toast" class:error={t.kind === 'error'}>
			<Icon name={t.kind === 'success' ? 'circle-check' : 'circle-exclamation'} size="1.5vmin" />
			<span class="message">{t.message}</span>
			<button type="button" class="close" onclick={() => dismissToast(t.id)} aria-label="Dismiss">
				<Icon name="xmark" size="1.1vmin" />
			</button>
		</div>
	{/each}
</div>

<style>
	.stack {
		position: absolute;
		bottom: 1.5vh;
		right: 1.5vw;
		display: flex;
		flex-direction: column-reverse;
		gap: 0.6vh;
		pointer-events: none;
		z-index: 200;
	}

	.toast {
		display: flex;
		align-items: center;
		gap: 0.8vw;
		background: rgba(6, 8, 10, 0.97);
		border: var(--border-subtle);
		border-left: 3px solid var(--color-success);
		border-radius: var(--radius);
		padding: 1.3vh 1.3vw;
		min-width: 19vw;
		max-width: 30vw;
		pointer-events: auto;
		color: var(--color-success);
	}

	.toast.error {
		border-left-color: var(--color-error);
		color: var(--color-error);
	}

	.message {
		flex: 1;
		font-size: 1.76vmin;
		color: var(--color-text);
	}

	.close {
		background: transparent;
		border: none;
		color: var(--color-text-muted);
		cursor: pointer;
		display: flex;
		padding: 0;
		flex-shrink: 0;
	}

	.close:hover {
		color: var(--color-text);
	}
</style>
