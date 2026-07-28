<!-- shared by AccountsView (Bank) and AtmShell (ATM), grouped Personal/Savings/Organization with a section label per group -->
<script lang="ts">
	import { financeState, selectAccount } from '../store/finance.svelte';
	import { getAccountTypeLabel } from '../../config';
	import { CURRENCY } from '../../config';
	import List from '../primitives/List.svelte';
	import Loader from '../primitives/Loader.svelte';
	import type { Account } from '../types';

	const groups = $derived.by(() => {
		const byType = (t: Account['Type']) => financeState.accounts.filter((a) => a.Type === t);
		const out: { label: string; accounts: Account[] }[] = [];
		const personal = byType('personal');
		const savings = byType('personal_savings');
		const org = byType('organization');
		if (personal.length) out.push({ label: 'Personal', accounts: personal });
		if (savings.length) out.push({ label: 'Savings', accounts: savings });
		if (org.length) out.push({ label: 'Organization', accounts: org });
		return out;
	});
</script>

<div class="list">
	{#if !financeState.accountsLoaded}
		<Loader text="Loading Accounts" />
	{:else if financeState.accounts.length === 0}
		<div class="empty">No Accounts</div>
	{:else}
		{#each groups as group (group.label)}
			<div class="group-label">{group.label}</div>
			{#each group.accounts as acc (acc.Account)}
				<List active={financeState.selectedAccount === acc.Account} onclick={() => selectAccount(acc.Account)}>
					<span class="cell">
						<span class="name">{acc.Name ?? getAccountTypeLabel(acc.Type)}</span>
						<span class="number">#{acc.Account}</span>
					</span>
					<span class="balance">{acc.Permissions?.BALANCE ? CURRENCY.format(acc.Balance) : '???'}</span>
				</List>
			{/each}
		{/each}
	{/if}
</div>

<style>
	.list {
		width: 100%;
		height: 100%;
		overflow-y: auto;
	}

	.group-label {
		padding: 1vh 1.1vw 0.4vh;
		font-size: 1.04vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.cell {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
	}

	.name {
		font-size: 1.49vmin;
		color: var(--color-text);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.number {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		margin-top: 0.2vh;
	}

	.balance {
		font-size: 1.43vmin;
		font-weight: 600;
		color: var(--color-success);
		white-space: nowrap;
	}

	.empty {
		text-align: center;
		padding: 3vh 0;
		color: var(--color-text-muted);
		font-size: 1.43vmin;
	}
</style>
