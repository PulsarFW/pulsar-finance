<script lang="ts">
	import Icon from './Icon.svelte';
	import { Nui } from './nui';
	import { financeState } from './store/finance.svelte';
	import { BRAND_ACCENTS, CURRENCY } from '../config';

	import fleecaLogo from '../assets/fleeca.png';
	import mazeLogo from '../assets/maze.png';
	import blainecoLogo from '../assets/blaineco.png';
	import udLogo from '../assets/ud.png';

	let { onCreate }: { onCreate?: () => void } = $props();

	const LOGOS = { fleeca: fleecaLogo, maze: mazeLogo, blaineco: blainecoLogo, ud: udLogo };

	const logo = $derived(LOGOS[financeState.brand] ?? fleecaLogo);
	const brandName = $derived(BRAND_ACCENTS[financeState.brand]?.name ?? 'Fleeca Bank');
</script>

<div class="titlebar">
	<div class="branding">
		<img class="logo" src={logo} alt={brandName} />
	</div>
	<div class="right">
		<div class="cash">
			Your Cash <span class="amount">{CURRENCY.format(financeState.character?.Cash ?? 0)}</span>
		</div>
		{#if onCreate}
			<button type="button" class="icon-btn" title="Open New Account" onclick={onCreate}>
				<Icon name="plus" size="1.5vmin" />
			</button>
		{/if}
		<button type="button" class="icon-btn" title="Close" onclick={() => Nui.close()}>
			<Icon name="xmark" size="1.5vmin" />
		</button>
	</div>
</div>

<style>
	.titlebar {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 1.4vh 1.4vw;
		border-bottom: var(--border-subtle);
	}

	.branding {
		display: flex;
		align-items: center;
	}

	.logo {
		height: 4vh;
		width: auto;
		object-fit: contain;
	}

	.right {
		display: flex;
		align-items: center;
		gap: 1vw;
	}

	.cash {
		font-size: 1.49vmin;
		color: var(--color-text-muted);
	}

	.amount {
		color: var(--color-success);
		font-weight: 600;
		margin-left: 0.4vw;
	}

	.icon-btn {
		background: transparent;
		border: none;
		color: rgba(230, 232, 236, 0.55);
		cursor: pointer;
		padding: 0.8vh 0.8vw;
		display: flex;
		border-radius: var(--radius);
		transition: color 120ms ease, background 120ms ease;
	}

	.icon-btn:hover {
		color: var(--color-primary-light);
		background: var(--color-primary-tint-soft);
	}
</style>
