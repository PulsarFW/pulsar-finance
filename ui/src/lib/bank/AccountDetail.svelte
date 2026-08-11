<script lang="ts">
	import { financeState, toast } from '../store/finance.svelte';
	import { Nui } from '../nui';
	import { CURRENCY, getAccountTypeLabel } from '../../config';
	import ActionButton from '../primitives/ActionButton.svelte';
	import Loader from '../primitives/Loader.svelte';
	import TransactionRow from './TransactionRow.svelte';
	import DepositModal from './DepositModal.svelte';
	import WithdrawModal from './WithdrawModal.svelte';
	import TransferModal from './TransferModal.svelte';
	import RenameModal from './RenameModal.svelte';
	import JointOwnersModal from './JointOwnersModal.svelte';
	import type { Account, Transaction } from '../types';

	let { trimmed = false }: { trimmed?: boolean } = $props();

	const account = $derived(financeState.accounts.find((a) => a.Account === financeState.selectedAccount) ?? null);

	let transactions = $state<Transaction[]>([]);
	let moreTransactions = $state(false);
	let loadingTx = $state(false);
	let lastLoadedAccount: string | number | null = null;

	let depositing = $state(false);
	let withdrawing = $state(false);
	let transferring = $state(false);
	let renaming = $state(false);
	let viewingOwners = $state(false);

	$effect(() => {
		const acc = account;
		if (!acc) {
			transactions = [];
			moreTransactions = false;
			lastLoadedAccount = null;
			return;
		}
		if (acc.Account !== lastLoadedAccount) {
			lastLoadedAccount = acc.Account;
			transactions = [];
			moreTransactions = false;
			if (!trimmed && acc.Permissions?.TRANSACTIONS) loadTransactions(acc);
		}
	});

	async function loadTransactions(acc: Account) {
		loadingTx = true;
		const res = await Nui.bankGetTransactions(acc.Account, transactions.length);
		loadingTx = false;
		if (res) {
			transactions = [...transactions, ...res.data];
			moreTransactions = res.more;
		}
	}

	function patchAccount(patch: Partial<Account>) {
		if (!account) return;
		const id = account.Account;
		financeState.accounts = financeState.accounts.map((a) => (a.Account === id ? { ...a, ...patch } : a));
	}

	function prependTx(tx: Transaction) {
		transactions = [tx, ...transactions];
	}

	function onDeposited(amount: number, balance: number, description: string) {
		if (!account) return;
		patchAccount({ Balance: balance });
		prependTx({ Amount: amount, Type: 'deposit', TransactionAccount: false, Title: 'Cash Deposit', Account: account.Account, Timestamp: Date.now() / 1000, Description: description });
	}

	function onWithdrawn(amount: number, balance: number, description: string) {
		if (!account) return;
		patchAccount({ Balance: balance });
		prependTx({ Amount: amount, Type: 'withdraw', TransactionAccount: false, Title: 'Cash Withdrawal', Account: account.Account, Timestamp: Date.now() / 1000, Description: description });
	}

	function onTransferred(amount: number, balance: number, target: string, byStateId: boolean, description: string) {
		if (!account) return;
		patchAccount({ Balance: balance });
		const suffix = description !== 'No Description' ? ` Description: ${description}` : '';
		prependTx({
			Amount: amount,
			Type: 'transfer',
			TransactionAccount: false,
			Title: 'Outgoing Bank Transfer',
			Account: account.Account,
			Timestamp: Date.now() / 1000,
			Description: `Transfer To ${byStateId ? 'State ID' : 'Account'}: ${target}.${suffix}`,
		});
		if (!byStateId) {
			const targetAccount = financeState.accounts.find((a) => String(a.Account) === target);
			if (targetAccount) financeState.accounts = financeState.accounts.map((a) => (a.Account === targetAccount.Account ? { ...a, Balance: a.Balance + amount } : a));
		}
	}

	function onRenamed(name: string) {
		patchAccount({ Name: name });
	}

	function onOwnersChanged(owners: number[]) {
		patchAccount({ JointOwners: owners });
	}
</script>

<div class="detail">
	{#if !account}
		<div class="empty">Select an account</div>
	{:else}
		<div class="header">
			<div class="name">{account.Name ?? getAccountTypeLabel(account.Type)}</div>
			<div class="meta">
				<span>{getAccountTypeLabel(account.Type)}</span>
				<span class="sep">•</span>
				<span>Account #{account.Account}</span>
			</div>
		</div>

		<div class="balance-row">
			<span class="label">Available Balance</span>
			<span class="balance">{account.Permissions?.BALANCE ? CURRENCY.format(account.Balance) : '???'}</span>
		</div>

		<div class="actions">
			<ActionButton label="Deposit Cash" variant="primary" disabled={!account?.Permissions?.DEPOSIT || financeState.character?.Cash === 0} onclick={() => (depositing = true)} />
			<ActionButton label="Withdraw Cash" disabled={!account?.Permissions?.WITHDRAW || account.Balance === 0} onclick={() => (withdrawing = true)} />
			{#if !trimmed}
				<ActionButton label="Transfer Funds" disabled={!account?.Permissions?.WITHDRAW || account.Balance === 0} onclick={() => (transferring = true)} />
				{#if account.Type !== 'organization'}
					<ActionButton label="Rename" disabled={!account?.Permissions?.MANAGE} onclick={() => (renaming = true)} />
				{/if}
				{#if account.Type === 'personal_savings' && account.Owner === financeState.character?.SID}
					<ActionButton label="Joint Owners" disabled={!account?.Permissions?.MANAGE} onclick={() => (viewingOwners = true)} />
				{/if}
			{/if}
		</div>

		{#if !trimmed}
			<div class="history">
				{#if !account.Permissions?.TRANSACTIONS}
					<div class="empty small">You don't have permission to view transaction history for this account</div>
				{:else}
					<div class="tx-list">
						{#each transactions as t, i (`${account.Account}-${t.Timestamp}-${i}`)}
							<TransactionRow transaction={t} />
						{/each}
						{#if transactions.length === 0 && !loadingTx}
							<div class="empty small">No Recent Transactions</div>
						{/if}
						{#if loadingTx}<Loader text="Loading" />{/if}
						{#if moreTransactions && transactions.length < 100 && !loadingTx}
							<div class="load-more"><ActionButton label="Load More" onclick={() => account && loadTransactions(account)} /></div>
						{/if}
					</div>
				{/if}
			</div>
		{/if}
	{/if}
</div>

{#if account}
	<DepositModal open={depositing} {account} onClose={() => (depositing = false)} onSuccess={onDeposited} />
	<WithdrawModal open={withdrawing} {account} onClose={() => (withdrawing = false)} onSuccess={onWithdrawn} />
	{#if !trimmed}
		<TransferModal open={transferring} {account} onClose={() => (transferring = false)} onSuccess={onTransferred} />
		<RenameModal open={renaming} {account} onClose={() => (renaming = false)} onSuccess={onRenamed} />
		<JointOwnersModal open={viewingOwners} {account} onClose={() => (viewingOwners = false)} onChanged={onOwnersChanged} />
	{/if}
{/if}

<style>
	.detail {
		flex: 1;
		min-width: 0;
		height: 100%;
		display: flex;
		flex-direction: column;
		padding: 1.6vh 1.4vw;
		overflow-y: auto;
	}

	.empty {
		margin: auto;
		text-align: center;
		color: var(--color-text-muted);
		font-size: 1.49vmin;
	}

	.empty.small {
		margin: 2vh auto;
		font-size: 1.37vmin;
	}

	.header {
		flex-shrink: 0;
	}

	.name {
		font-family: var(--font-heading);
		font-size: 2.21vmin;
		font-weight: 600;
		color: var(--color-text);
	}

	.meta {
		margin-top: 0.4vh;
		font-size: 1.3vmin;
		color: var(--color-text-muted);
	}

	.sep {
		margin: 0 0.4vw;
	}

	.balance-row {
		flex-shrink: 0;
		margin-top: 1.6vh;
		display: flex;
		flex-direction: column;
	}

	.balance-row .label {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.balance {
		font-size: 3.12vmin;
		font-weight: 700;
		color: var(--color-success);
		margin-top: 0.3vh;
	}

	.actions {
		flex-shrink: 0;
		margin-top: 1.6vh;
		display: flex;
		flex-wrap: wrap;
		gap: 0.6vw;
	}

	.history {
		flex: 1;
		min-height: 0;
		margin-top: 1.8vh;
		border-top: var(--border-subtle);
	}

	.tx-list {
		height: 100%;
		overflow-y: auto;
	}

	.load-more {
		padding: 1.2vh 0;
	}
</style>
