<!-- paid-off loans (Remaining <= 0) show a settled badge, MissedPayments > 0 highlights in red since missed payments raise InterestRate (see server/components/loans/loans.lua) -->
<script lang="ts">
	import Icon from '../Icon.svelte';
	import ActionButton from '../primitives/ActionButton.svelte';
	import { CURRENCY, getLoanIdentifierLabel, getLoanTypeLabel, getNextPaymentAmount, getPayoffAmount } from '../../config';
	import type { Loan } from '../types';

	let { loan, onPay }: { loan: Loan; onPay: () => void } = $props();

	const paidOff = $derived(loan.Remaining <= 0);
	const nextDue = $derived(getNextPaymentAmount(loan));
	const payoff = $derived(getPayoffAmount(loan));

	function formatDate(ts: number): string {
		if (!ts) return '—';
		return new Date(ts * 1000).toLocaleDateString('en-US', { dateStyle: 'medium' });
	}
</script>

<div class="row" class:paid={paidOff} class:defaulted={loan.Defaulted}>
	<div class="icon"><Icon name="landmark" size="1.6vmin" /></div>
	<div class="info">
		<div class="top">
			<span class="title">{getLoanTypeLabel(loan.Type)}</span>
			{#if paidOff}
				<span class="badge success">Paid Off</span>
			{:else if loan.Defaulted}
				<span class="badge danger">Defaulted</span>
			{:else if loan.MissedPayments > 0}
				<span class="badge warning">{loan.MissedPayments} Missed Payment{loan.MissedPayments === 1 ? '' : 's'}</span>
			{/if}
		</div>
		<div class="identifier">{getLoanIdentifierLabel(loan.Type)}: {loan.AssetIdentifier}</div>

		<div class="stats">
			<div class="stat"><span class="label">Remaining</span><span class="value">{CURRENCY.format(loan.Remaining)}</span></div>
			<div class="stat"><span class="label">Interest Rate</span><span class="value">{loan.InterestRate}%</span></div>
			<div class="stat"><span class="label">Progress</span><span class="value">{loan.PaidPayments}/{loan.TotalPayments}</span></div>
			{#if !paidOff}
				<div class="stat"><span class="label">Next Payment Due</span><span class="value">{formatDate(loan.NextPayment)}</span></div>
			{/if}
		</div>
	</div>

	{#if !paidOff}
		<div class="pay">
			<div class="pay-amount">{CURRENCY.format(nextDue)}</div>
			<div class="pay-sub">Payoff: {CURRENCY.format(payoff)}</div>
			<ActionButton label="Make Payment" variant="primary" onclick={onPay} />
		</div>
	{/if}
</div>

<style>
	.row {
		display: flex;
		gap: 1vw;
		padding: 1.4vh 1.2vw;
		border: var(--border-subtle);
		border-radius: var(--radius);
		margin-bottom: 1vh;
	}

	.row.paid {
		opacity: 0.7;
	}

	.row.defaulted {
		border-color: rgba(217, 82, 90, 0.4);
	}

	.icon {
		flex-shrink: 0;
		width: 3.2vh;
		height: 3.2vh;
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: 50%;
		background: var(--color-primary-tint-medium);
		color: var(--color-primary-light);
	}

	.info {
		flex: 1;
		min-width: 0;
	}

	.top {
		display: flex;
		align-items: center;
		gap: 0.6vw;
	}

	.title {
		font-size: 1.62vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.badge {
		font-size: 1.04vmin;
		font-weight: 600;
		padding: 0.2vh 0.6vw;
		border-radius: var(--radius);
		text-transform: uppercase;
	}

	.badge.success {
		color: var(--color-success);
		background: rgba(67, 168, 102, 0.14);
	}

	.badge.danger {
		color: var(--color-error);
		background: rgba(217, 82, 90, 0.14);
	}

	.badge.warning {
		color: var(--color-warning);
		background: rgba(217, 154, 61, 0.14);
	}

	.identifier {
		font-size: 1.23vmin;
		color: var(--color-text-muted);
		margin-top: 0.2vh;
	}

	.stats {
		display: flex;
		flex-wrap: wrap;
		gap: 1.4vw;
		margin-top: 1vh;
	}

	.stat {
		display: flex;
		flex-direction: column;
	}

	.stat .label {
		font-size: 0.98vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
	}

	.stat .value {
		font-size: 1.37vmin;
		color: var(--color-text);
		margin-top: 0.15vh;
	}

	.pay {
		flex-shrink: 0;
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		justify-content: center;
		gap: 0.4vh;
	}

	.pay-amount {
		font-size: 1.69vmin;
		font-weight: 700;
		color: var(--color-text);
	}

	.pay-sub {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
	}
</style>
