<!-- see DepositModal.svelte for why onSuccess reports back rather than the caller re-deriving state from a mutated array -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import { Nui } from '../nui';
	import { toast } from '../store/finance.svelte';
	import type { Account } from '../types';

	let {
		open,
		account,
		onClose,
		onSuccess,
	}: { open: boolean; account: Account; onClose: () => void; onSuccess: (amount: number, balance: number, description: string) => void } = $props();

	let amount = $state('');
	let notes = $state('');
	let loading = $state(false);

	async function submit() {
		const amt = Number(amount);
		if (!amt || amt <= 0) return;
		loading = true;
		const res = await Nui.bankWithdraw(account.Account, amt, notes);
		loading = false;
		if (res.state) {
			toast.success('Funds Withdrawn');
			onSuccess(amt, res.balance ?? account.Balance - amt, notes || 'No Description');
			amount = '';
			notes = '';
			onClose();
		} else {
			toast.error('Unable To Withdraw Funds');
		}
	}
</script>

<Modal
	open={open && !!account?.Permissions?.WITHDRAW}
	title={`Withdraw Funds From ${account.Name ?? 'Account'}`}
	submitLabel="Withdraw"
	{loading}
	{onClose}
	onSubmit={submit}
>
	<Field label="Withdraw From" name="target" value={String(account.Account)} disabled />
	<Field label="Amount" name="amount" type="number" bind:value={amount} required min={1} />
	<Field label="Transaction Comment" name="notes" bind:value={notes} placeholder="Optional" />
</Modal>
