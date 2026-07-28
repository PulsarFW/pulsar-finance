<!-- Bank apps Accounts tab, two-column layout (list + detail), fetches once when the tab first mounts -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { financeState, refreshAccounts } from '../store/finance.svelte';
	import AccountList from './AccountList.svelte';
	import AccountDetail from './AccountDetail.svelte';

	onMount(() => {
		if (!financeState.accountsLoaded) refreshAccounts();
	});
</script>

<div class="view">
	<div class="sidebar">
		<AccountList />
	</div>
	<AccountDetail />
</div>

<style>
	.view {
		flex: 1;
		min-height: 0;
		display: flex;
	}

	.sidebar {
		width: 15vw;
		min-width: 200px;
		flex-shrink: 0;
		border-right: var(--border-subtle);
		overflow-y: auto;
	}
</style>
