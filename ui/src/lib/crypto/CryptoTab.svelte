<!-- no chart, prices are static and set once at coin creation, no history table or price-tick task exists to chart -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { financeState, applyCrypto } from '../store/finance.svelte';
	import { Nui } from '../nui';
	import Loader from '../primitives/Loader.svelte';
	import Icon from '../Icon.svelte';
	import CoinRow from './CoinRow.svelte';
	import BuySellModal from './BuySellModal.svelte';
	import TransferModal from './TransferModal.svelte';
	import type { CryptoCoin } from '../types';

	let tradeCoin = $state<CryptoCoin | null>(null);
	let tradeMode = $state<'buy' | 'sell'>('buy');
	let transferCoin = $state<CryptoCoin | null>(null);

	onMount(async () => {
		if (financeState.cryptoLoaded) return;
		const [coins, wallet] = await Promise.all([Nui.cryptoGetAll(), Nui.cryptoGetWallet()]);
		applyCrypto(coins, wallet || null);
	});

	function holdingsFor(short: string): number {
		return financeState.cryptoWallet?.Holdings[short] ?? 0;
	}
</script>

<div class="tab">
	{#if !financeState.cryptoLoaded}
		<Loader text="Loading Crypto" />
	{:else}
		{#if financeState.cryptoWallet}
			<div class="wallet-id">
				<Icon name="wallet" size="1.1vmin" />
				Wallet ID <span class="id">{financeState.cryptoWallet.WalletId}</span>
			</div>
		{/if}

		<div class="list">
			{#if financeState.cryptoCoins.length === 0}
				<div class="empty">No Coins Available</div>
			{:else}
				{#each financeState.cryptoCoins as coin (coin.Short)}
					<CoinRow
						{coin}
						holdings={holdingsFor(coin.Short)}
						onBuy={() => {
							tradeCoin = coin;
							tradeMode = 'buy';
						}}
						onSell={() => {
							tradeCoin = coin;
							tradeMode = 'sell';
						}}
						onTransfer={() => (transferCoin = coin)}
					/>
				{/each}
			{/if}
		</div>
	{/if}
</div>

<BuySellModal open={!!tradeCoin} mode={tradeMode} coin={tradeCoin} holdings={tradeCoin ? holdingsFor(tradeCoin.Short) : 0} onClose={() => (tradeCoin = null)} />
<TransferModal open={!!transferCoin} coin={transferCoin} holdings={transferCoin ? holdingsFor(transferCoin.Short) : 0} onClose={() => (transferCoin = null)} />

<style>
	.tab {
		flex: 1;
		min-height: 0;
		display: flex;
		flex-direction: column;
		padding: 1.6vh 1.4vw;
		overflow-y: auto;
	}

	.wallet-id {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.5vw;
		font-size: 1.3vmin;
		color: var(--color-text-muted);
		margin-bottom: 1.4vh;
	}

	.id {
		color: var(--color-text);
		font-weight: 600;
		letter-spacing: 0.04em;
	}

	.list {
		flex: 1;
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.43vmin;
	}
</style>
