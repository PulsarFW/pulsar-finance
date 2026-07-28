<!-- target is the destination player's CryptoWallet id, a 5-char string, not a state ID -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import { Nui } from '../nui';
	import { financeState, applyCrypto, toast } from '../store/finance.svelte';
	import type { CryptoCoin } from '../types';

	let { open, coin, holdings, onClose }: { open: boolean; coin: CryptoCoin | null; holdings: number; onClose: () => void } = $props();

	let target = $state('');
	let amount = $state('');
	let loading = $state(false);

	async function submit() {
		if (!coin) return;
		const amt = Number(amount);
		if (!amt || amt <= 0 || !target) return;
		if (amt > holdings) {
			toast.error('You Do Not Have That Many Coins');
			return;
		}
		if (target === financeState.cryptoWallet?.WalletId) {
			toast.error('Cannot Transfer To Your Own Wallet');
			return;
		}

		loading = true;
		const ok = await Nui.cryptoTransfer(coin.Short, target, amt);
		loading = false;

		if (ok) {
			toast.success('Coins Transferred');
			const wallet = financeState.cryptoWallet;
			if (wallet) applyCrypto(financeState.cryptoCoins, { ...wallet, Holdings: { ...wallet.Holdings, [coin.Short]: (wallet.Holdings[coin.Short] ?? 0) - amt } });
			target = '';
			amount = '';
			onClose();
		} else {
			toast.error('Unable To Transfer Coins');
		}
	}
</script>

{#if coin}
	<Modal open={open} title={`Transfer ${coin.Name}`} submitLabel="Transfer" {loading} {onClose} onSubmit={submit}>
		<Field label="Destination Wallet ID" name="target" bind:value={target} required />
		<Field label="Amount" name="amount" type="number" bind:value={amount} required min={1} step={1} />
		<div class="row"><span class="label">You Own</span><span class="value">{holdings}</span></div>
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
</style>
