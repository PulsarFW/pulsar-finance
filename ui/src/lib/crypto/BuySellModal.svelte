<!-- Buy/Sell confirmation, one component for both since they're the same form shape, see server/components/crypto/component.lua -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import { Nui } from '../nui';
	import { financeState, applyCrypto, toast } from '../store/finance.svelte';
	import { CURRENCY } from '../../config';
	import type { CryptoCoin } from '../types';

	let {
		open,
		mode,
		coin,
		holdings,
		onClose,
	}: { open: boolean; mode: 'buy' | 'sell'; coin: CryptoCoin | null; holdings: number; onClose: () => void } = $props();

	let amount = $state('');
	let loading = $state(false);

	const unitPrice = $derived(coin ? (mode === 'buy' ? coin.Price : typeof coin.Sellable === 'number' ? coin.Sellable : 0) : 0);
	const total = $derived(unitPrice * (Number(amount) || 0));

	async function submit() {
		if (!coin) return;
		const amt = Number(amount);
		if (!amt || amt <= 0) return;
		if (mode === 'sell' && amt > holdings) {
			toast.error('You Do Not Have That Many Coins');
			return;
		}

		loading = true;
		const ok = mode === 'buy' ? await Nui.cryptoBuy(coin.Short, amt) : await Nui.cryptoSell(coin.Short, amt);
		loading = false;

		if (ok) {
			toast.success(mode === 'buy' ? 'Coins Purchased' : 'Coins Sold');
			const wallet = financeState.cryptoWallet;
			if (wallet) {
				const delta = mode === 'buy' ? amt : -amt;
				applyCrypto(financeState.cryptoCoins, { ...wallet, Holdings: { ...wallet.Holdings, [coin.Short]: (wallet.Holdings[coin.Short] ?? 0) + delta } });
			}
			amount = '';
			onClose();
		} else {
			toast.error(mode === 'buy' ? 'Unable To Buy Coins' : 'Unable To Sell Coins');
		}
	}
</script>

{#if coin}
	<Modal open={open} title={`${mode === 'buy' ? 'Buy' : 'Sell'} ${coin.Name}`} submitLabel={mode === 'buy' ? 'Buy' : 'Sell'} {loading} {onClose} onSubmit={submit}>
		<Field label="Amount" name="amount" type="number" bind:value={amount} required min={1} step={1} />
		<div class="row"><span class="label">Price Per Coin</span><span class="value">{CURRENCY.format(unitPrice)}</span></div>
		<div class="row"><span class="label">Total</span><span class="value amount">{CURRENCY.format(total)}</span></div>
		{#if mode === 'sell'}
			<div class="row"><span class="label">You Own</span><span class="value">{holdings}</span></div>
		{/if}
	</Modal>
{/if}

<style>
	.row {
		display: flex;
		justify-content: space-between;
		padding: 0.7vh 0;
		border-bottom: var(--border-subtle);
		font-size: 1.37vmin;
	}

	.label {
		color: var(--color-text-muted);
	}

	.value {
		color: var(--color-text);
	}

	.value.amount {
		color: var(--color-success);
		font-weight: 600;
	}
</style>
