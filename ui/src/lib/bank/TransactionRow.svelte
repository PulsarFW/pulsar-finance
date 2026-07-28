<!-- Transaction.Type covers more than this UI's deposit/withdraw/transfer, other resources post fine/bill/paycheck into the same log, unknown types fall back to a generic glyph -->
<script lang="ts">
	import Icon from '../Icon.svelte';
	import Modal from '../primitives/Modal.svelte';
	import { CURRENCY } from '../../config';
	import type { Transaction } from '../types';

	let { transaction }: { transaction: Transaction } = $props();

	let viewing = $state(false);

	const ICONS: Record<string, string> = {
		transfer: 'right-left',
		withdraw: 'arrow-up',
		deposit: 'arrow-down',
		fine: 'triangle-exclamation',
		bill: 'triangle-exclamation',
		fine_profit: 'coins',
		paycheck: 'wallet',
	};

	const NEGATIVE: Record<string, boolean> = { withdraw: true, fine: true, bill: true };

	function formatDate(ts: number): string {
		return new Date(ts * 1000).toLocaleString('en-US', { dateStyle: 'medium', timeStyle: 'short' });
	}
</script>

<button type="button" class="row" onclick={() => (viewing = true)}>
	<span class="icon" class:negative={NEGATIVE[transaction.Type]}>
		<Icon name={ICONS[transaction.Type] ?? 'wallet'} size="1.1vmin" />
	</span>
	<span class="cell title">
		<span class="label">{transaction.Title}</span>
		<span class="sub">{formatDate(transaction.Timestamp)}</span>
	</span>
	<span class="cell desc">{transaction.Description}</span>
	<span class="amount" class:negative={NEGATIVE[transaction.Type]}>
		{NEGATIVE[transaction.Type] ? '-' : '+'}{CURRENCY.format(transaction.Amount)}
	</span>
</button>

<Modal open={viewing} title="Transaction Details" closeLabel="Close" onClose={() => (viewing = false)}>
	<div class="detail-row"><span class="label">Title</span><span class="value">{transaction.Title}</span></div>
	<div class="detail-row"><span class="label">Type</span><span class="value">{transaction.Type}</span></div>
	<div class="detail-row"><span class="label">Description</span><span class="value">{transaction.Description}</span></div>
	<div class="detail-row"><span class="label">Date</span><span class="value">{formatDate(transaction.Timestamp)}</span></div>
	<div class="detail-row"><span class="label">Amount</span><span class="value amount">{CURRENCY.format(transaction.Amount)}</span></div>
</Modal>

<style>
	.row {
		display: flex;
		align-items: center;
		gap: 0.9vw;
		width: 100%;
		padding: 1vh 1vw;
		background: transparent;
		border: none;
		border-bottom: var(--border-subtle);
		font-family: inherit;
		text-align: left;
		color: inherit;
		cursor: pointer;
		transition: background 120ms ease;
	}

	.row:hover {
		background: var(--color-primary-tint-soft);
	}

	.icon {
		flex-shrink: 0;
		width: 2.6vh;
		height: 2.6vh;
		display: flex;
		align-items: center;
		justify-content: center;
		border-radius: 50%;
		background: var(--color-primary-tint-medium);
		color: var(--color-primary-light);
	}

	.icon.negative {
		background: rgba(217, 82, 90, 0.16);
		color: var(--color-error);
	}

	.cell {
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.title {
		width: 30%;
		flex-shrink: 0;
	}

	.desc {
		flex: 1;
		color: var(--color-text-muted);
		font-size: 1.3vmin;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.label {
		font-size: 1.37vmin;
		color: var(--color-text);
	}

	.sub {
		font-size: 1.04vmin;
		color: var(--color-text-muted);
		margin-top: 0.15vh;
	}

	.amount {
		flex-shrink: 0;
		font-size: 1.43vmin;
		font-weight: 600;
		color: var(--color-success);
	}

	.amount.negative {
		color: var(--color-error);
	}

	.detail-row {
		display: flex;
		justify-content: space-between;
		gap: 1vw;
		padding: 0.8vh 0;
		border-bottom: var(--border-subtle);
		font-size: 1.43vmin;
	}

	.detail-row .label {
		color: var(--color-text-muted);
	}

	.detail-row .value {
		color: var(--color-text);
		text-align: right;
	}

	.detail-row .value.amount {
		color: var(--color-success);
	}
</style>
