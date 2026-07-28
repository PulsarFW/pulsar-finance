<script lang="ts">
	import ActionButton from '../primitives/ActionButton.svelte';
	import { CURRENCY } from '../../config';
	import type { CryptoCoin } from '../types';

	let {
		coin,
		holdings,
		onBuy,
		onSell,
		onTransfer,
	}: { coin: CryptoCoin; holdings: number; onBuy: () => void; onSell: () => void; onTransfer: () => void } = $props();

	const sellPrice = $derived(typeof coin.Sellable === 'number' ? coin.Sellable : null);
</script>

<div class="row">
	<div class="info">
		<div class="top">
			<span class="name">{coin.Name}</span>
			<span class="short">{coin.Short}</span>
		</div>
		<div class="prices">
			<span class="price">{CURRENCY.format(coin.Price)}</span>
			{#if sellPrice != null && sellPrice !== coin.Price}
				<span class="sell-price">sells {CURRENCY.format(sellPrice)}</span>
			{/if}
		</div>
	</div>

	<div class="holdings">
		<span class="label">Holdings</span>
		<span class="value">{holdings}</span>
	</div>

	<div class="actions">
		<ActionButton label="Buy" variant="primary" disabled={!coin.Buyable} onclick={onBuy} />
		<ActionButton label="Sell" disabled={!coin.Sellable || holdings <= 0} onclick={onSell} />
		<ActionButton label="Transfer" disabled={holdings <= 0} onclick={onTransfer} />
	</div>
</div>

<style>
	.row {
		display: flex;
		align-items: center;
		gap: 1.2vw;
		padding: 1.2vh 1.2vw;
		border: var(--border-subtle);
		border-radius: var(--radius);
		margin-bottom: 1vh;
	}

	.info {
		flex: 1;
		min-width: 0;
	}

	.top {
		display: flex;
		align-items: baseline;
		gap: 0.6vw;
	}

	.name {
		font-size: 1.56vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.short {
		font-size: 1.17vmin;
		color: var(--color-text-muted);
	}

	.prices {
		margin-top: 0.3vh;
		display: flex;
		gap: 0.8vw;
	}

	.price {
		font-size: 1.37vmin;
		color: var(--color-success);
		font-weight: 600;
	}

	.sell-price {
		font-size: 1.17vmin;
		color: var(--color-text-muted);
	}

	.holdings {
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		min-width: 6vw;
	}

	.holdings .label {
		font-size: 0.98vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
	}

	.holdings .value {
		font-size: 1.56vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.actions {
		flex-shrink: 0;
		display: flex;
		gap: 0.5vw;
	}
</style>
