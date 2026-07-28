<!-- same account list + detail pane as the Bank app, trimmed to deposit/withdraw only, no tab bar since Loans/Crypto are Bank-only -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { financeState, refreshAccounts } from '../store/finance.svelte';
	import AccountList from '../bank/AccountList.svelte';
	import AccountDetail from '../bank/AccountDetail.svelte';

	onMount(() => {
		if (!financeState.accountsLoaded) refreshAccounts();
	});
</script>

<div class="view">
	<div class="sidebar">
		<AccountList />
	</div>
	<AccountDetail trimmed />
</div>

<style>
	.view {
		flex: 1;
		min-height: 0;
		display: flex;
	}

	.sidebar {
		width: 12vw;
		min-width: 150px;
		flex-shrink: 0;
		border-right: var(--border-subtle);
		overflow-y: auto;
	}
</style>
