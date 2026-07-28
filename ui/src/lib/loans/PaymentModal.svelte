<!-- no amount field, the server always pays exactly 1 cycle (or auto-catches-up missed cycles), see server/components/loans/loans.lua's MakePayment -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import { Nui } from '../nui';
	import { applyLoans, toast } from '../store/finance.svelte';
	import { CURRENCY, getNextPaymentAmount } from '../../config';
	import type { Loan } from '../types';

	let { open, loan, onClose }: { open: boolean; loan: Loan | null; onClose: () => void } = $props();

	let loading = $state(false);

	const dueAmount = $derived(loan ? getNextPaymentAmount(loan) : 0);

	async function submit() {
		if (!loan) return;
		loading = true;
		const { result, refreshed } = await Nui.loansPayment(loan._id);
		loading = false;
		if (result.success) {
			toast.success(result.paidOff ? 'Loan Paid Off!' : `Payment of ${CURRENCY.format(result.paymentAmount ?? dueAmount)} Made`);
			if (refreshed) applyLoans(refreshed.loans, refreshed.creditScore);
		} else {
			toast.error(result.message ?? 'Unable To Make Payment');
		}
		onClose();
	}
</script>

{#if loan}
	<Modal open={open} title="Make Loan Payment" submitLabel="Pay" {loading} {onClose} onSubmit={submit}>
		<div class="row"><span class="label">Asset</span><span class="value">{loan.AssetIdentifier}</span></div>
		<div class="row"><span class="label">Amount Due</span><span class="value amount">{CURRENCY.format(dueAmount)}</span></div>
		{#if loan.MissedPayments > 0}
			<p class="hint">This loan has {loan.MissedPayments} missed payment{loan.MissedPayments === 1 ? '' : 's'} — this payment will catch up all of them at once.</p>
		{/if}
	</Modal>
{/if}

<style>
	.row {
		display: flex;
		justify-content: space-between;
		padding: 0.8vh 0;
		border-bottom: var(--border-subtle);
		font-size: 1.43vmin;
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

	.hint {
		margin: 1.2vh 0 0;
		font-size: 1.3vmin;
		color: var(--color-warning);
		line-height: 1.5;
	}
</style>
