<!-- account type is always 'personal_savings'. no Account Name field, server/components/banking/callbacks.lua -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import { Nui } from '../nui';
	import { financeState, selectAccount, toast } from '../store/finance.svelte';
	import type { Account } from '../types';

	let { open, onClose }: { open: boolean; onClose: () => void } = $props();

	let loading = $state(false);

	async function submit() {
		if (financeState.accounts.some((a) => a.Owner === financeState.character?.SID && a.Type === 'personal_savings')) {
			toast.error('You May Only Own 1 Savings Account');
			onClose();
			return;
		}

		loading = true;
		const acc = await Nui.bankRegister('personal_savings');
		loading = false;
		if (acc) {
			financeState.accounts = [...financeState.accounts, acc as Account];
			selectAccount((acc as Account).Account);
			onClose();
		} else {
			toast.error('Unable To Open Account');
		}
	}
</script>

<Modal {open} title="Open New Account" submitLabel="Open Account" {loading} {onClose} onSubmit={submit}>
	<p class="hint">Opens a new Personal Savings account. You can give it a nickname afterward from the account detail view.</p>
</Modal>

<style>
	.hint {
		margin: 0;
		font-size: 1.43vmin;
		color: var(--color-text-muted);
		line-height: 1.5;
	}
</style>
