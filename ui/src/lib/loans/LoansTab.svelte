<!-- not a loan-shopping flow, origination happens in pulsar_dealerships/pulsar_properties at purchase time -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { financeState, applyLoans } from '../store/finance.svelte';
	import { Nui } from '../nui';
	import Loader from '../primitives/Loader.svelte';
	import CreditScoreCard from './CreditScoreCard.svelte';
	import LoanRow from './LoanRow.svelte';
	import PaymentModal from './PaymentModal.svelte';
	import type { Loan } from '../types';

	let paying = $state<Loan | null>(null);

	onMount(async () => {
		if (financeState.loansLoaded) return;
		const res = await Nui.loansGetLoans();
		if (res) applyLoans(res.loans, res.creditScore);
	});

	const active = $derived(financeState.loans.filter((l) => l.Remaining > 0));
	const settled = $derived(financeState.loans.filter((l) => l.Remaining <= 0));
</script>

<div class="tab">
	{#if !financeState.loansLoaded}
		<Loader text="Loading Loans" />
	{:else}
		<div class="score">
			<CreditScoreCard score={financeState.creditScore} />
		</div>

		<div class="list">
			{#if financeState.loans.length === 0}
				<div class="empty">No Loans</div>
			{:else}
				{#if active.length > 0}
					<div class="section-label">Active</div>
					{#each active as loan (loan._id)}
						<LoanRow {loan} onPay={() => (paying = loan)} />
					{/each}
				{/if}
				{#if settled.length > 0}
					<div class="section-label">Settled</div>
					{#each settled as loan (loan._id)}
						<LoanRow {loan} onPay={() => (paying = loan)} />
					{/each}
				{/if}
			{/if}
		</div>
	{/if}
</div>

<PaymentModal open={!!paying} loan={paying} onClose={() => (paying = null)} />

<style>
	.tab {
		flex: 1;
		min-height: 0;
		display: flex;
		flex-direction: column;
		padding: 1.6vh 1.4vw;
		overflow-y: auto;
	}

	.score {
		flex-shrink: 0;
		margin-bottom: 1.6vh;
	}

	.list {
		flex: 1;
	}

	.section-label {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.06em;
		margin: 1.2vh 0 0.6vh;
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.43vmin;
	}
</style>
