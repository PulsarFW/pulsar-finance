<!-- type is State ID (another player's personal account) or Account Number (any account, including your own others) -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import { Nui } from '../nui';
	import { financeState, toast } from '../store/finance.svelte';
	import type { Account } from '../types';

	let {
		open,
		account,
		onClose,
		onSuccess,
	}: { open: boolean; account: Account; onClose: () => void; onSuccess: (amount: number, balance: number, target: string, byStateId: boolean, description: string) => void } = $props();

	let byStateId = $state(false);
	let target = $state('');
	let amount = $state('');
	let notes = $state('');
	let loading = $state(false);

	async function submit() {
		const amt = Number(amount);
		if (!amt || amt <= 0 || !target) return;

		if (byStateId && Number(target) === financeState.character?.SID) {
			toast.error('Cannot Transfer To Your Own State ID, Use Account Numbers');
			return;
		}
		if (!byStateId && target === String(account.Account)) {
			toast.error('Cannot Transfer Funds To The Same Account');
			return;
		}

		loading = true;
		const res = await Nui.bankTransfer(account.Account, byStateId, target, amt, notes);
		loading = false;
		if (res.state) {
			toast.success('Funds Transferred');
			onSuccess(amt, res.balance ?? account.Balance - amt, target, byStateId, notes || 'No Description');
			target = '';
			amount = '';
			notes = '';
			onClose();
		} else {
			toast.error('Unable To Transfer Funds');
		}
	}
</script>

<Modal open={open && !!account?.Permissions?.WITHDRAW} title={`Transfer Funds From ${account.Name ?? 'Account'}`} submitLabel="Transfer" {loading} {onClose} onSubmit={submit}>
	<Field label="Transfer From" name="source" value={String(account.Account)} disabled />
	<label class="field">
		<span class="label">Transfer Type</span>
		<select class="input" bind:value={byStateId}>
			<option value={false}>Account Number</option>
			<option value={true}>State ID</option>
		</select>
	</label>
	<Field label={byStateId ? 'State ID' : 'Account Number'} name="target" type="number" bind:value={target} required />
	<Field label="Amount" name="amount" type="number" bind:value={amount} required min={1} />
	<Field label="Transaction Comment" name="notes" bind:value={notes} placeholder="Optional" />
</Modal>

<style>
	.field {
		display: block;
		margin-bottom: 1.2vh;
	}

	.label {
		display: block;
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		margin-bottom: 0.5vh;
	}

	.input {
		width: 100%;
		background: rgba(230, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.56vmin;
		padding: 0.9vh 0.9vw;
	}
</style>
