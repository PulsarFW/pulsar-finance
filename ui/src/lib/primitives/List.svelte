<!-- generic clickable list row, one consistent dot-indicator hover-row language -->
<script lang="ts">
	import type { Snippet } from 'svelte';

	let { onclick, disabled = false, active = false, children }: { onclick?: () => void; disabled?: boolean; active?: boolean; children: Snippet } = $props();

	const clickable = $derived(!!onclick && !disabled);
</script>

<svelte:element
	this={clickable ? 'button' : 'div'}
	type={clickable ? 'button' : undefined}
	role={clickable ? 'button' : undefined}
	class="row"
	class:clickable
	class:disabled
	class:active
	onclick={clickable ? onclick : undefined}
>
	<span class="dot"></span>
	<div class="content">
		{@render children()}
	</div>
</svelte:element>

<style>
	.row {
		display: flex;
		align-items: center;
		gap: 0.8vw;
		width: 100%;
		padding: 1.1vh 1.1vw;
		background: transparent;
		border: none;
		border-bottom: var(--border-subtle);
		font-family: inherit;
		text-align: left;
		color: inherit;
		transition: background 120ms ease;
	}

	.row.clickable {
		cursor: pointer;
	}

	.row.clickable:hover,
	.row.active {
		background: var(--color-primary-tint-soft);
	}

	.row.clickable:hover .dot,
	.row.active .dot {
		background: var(--color-primary);
	}

	.row.disabled {
		opacity: 0.5;
	}

	.dot {
		width: 5px;
		height: 5px;
		border-radius: 50%;
		background: rgba(230, 232, 236, 0.2);
		flex-shrink: 0;
		transition: background 120ms ease;
	}

	.content {
		flex: 1;
		min-width: 0;
		display: flex;
		align-items: center;
		gap: 1.5vw;
	}
</style>
