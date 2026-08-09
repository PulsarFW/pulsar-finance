<!-- same account list + detail pane as the Bank app, trimmed to deposit/withdraw only, no tab bar since Loans/Crypto are Bank-only -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { financeState, refreshAccounts, selectAccount } from '../store/finance.svelte';
	import AccountList from '../bank/AccountList.svelte';
	import AccountDetail from '../bank/AccountDetail.svelte';
	import Icon from '../Icon.svelte';

	onMount(() => {
		if (!financeState.accountsLoaded) refreshAccounts();
	});
</script>

<div class="view">
	{#if financeState.selectedAccount === null}
		<AccountList />
	{:else}
		<button type="button" class="back" onclick={() => selectAccount(null)}>
			<Icon name="chevron-left" size="1vmin" />
			Accounts
		</button>
		<AccountDetail trimmed />
	{/if}
</div>

<style>
	.view {
		flex: 1;
		min-height: 0;
		display: flex;
		flex-direction: column;
	}

	.back {
		flex-shrink: 0;
		display: flex;
		align-items: center;
		gap: 0.5vw;
		padding: 1vh 1.4vw;
		background: transparent;
		border: none;
		border-bottom: var(--border-subtle);
		color: var(--color-text-muted);
		font-size: 1.1vmin;
		font-family: var(--font-body);
		cursor: pointer;
		text-align: left;
	}

	.back:hover {
		color: var(--color-text);
	}
</style>
