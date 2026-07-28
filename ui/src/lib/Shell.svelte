<!-- renders the Bank app (tab bar for Accounts/Loans/Crypto) or the ATM app (AtmShell, no tab bar, Loans/Crypto are Bank-only).
	the active brands accent palette (config.ts's BRAND_ACCENTS) applies here as inline custom-property overrides on the panel root -->
<script lang="ts">
	import { financeState, setTab } from './store/finance.svelte';
	import { BRAND_ACCENTS } from '../config';
	import Icon from './Icon.svelte';
	import Titlebar from './Titlebar.svelte';
	import Toast from './Toast.svelte';
	import AccountsView from './bank/AccountsView.svelte';
	import CreateAccountModal from './bank/CreateAccountModal.svelte';
	import LoansTab from './loans/LoansTab.svelte';
	import CryptoTab from './crypto/CryptoTab.svelte';
	import AtmShell from './atm/AtmShell.svelte';

	let creating = $state(false);

	const brand = $derived(BRAND_ACCENTS[financeState.brand]);
	const brandStyle = $derived(
		`--color-primary:${brand.primary};--color-primary-light:${brand.primaryLight};--color-primary-dark:${brand.primaryDark};` +
		`--color-primary-tint-soft:${brand.tintSoft};--color-primary-tint-medium:${brand.tintMedium};--border-primary:${brand.borderPrimary};`,
	);

	const showCreate = $derived(financeState.app === 'BANK' && financeState.tab === 'accounts');
</script>

{#if !financeState.hidden}
	<div class="panel" class:atm={financeState.app === 'ATM'} style={brandStyle}>
		<Titlebar onCreate={showCreate ? () => (creating = true) : undefined} />

		{#if financeState.app === 'BANK'}
			<div class="tabs">
				<button type="button" class="tab" class:active={financeState.tab === 'accounts'} onclick={() => setTab('accounts')}>
					<Icon name="wallet" size="1.2vmin" />
					Accounts
				</button>
				<button type="button" class="tab" class:active={financeState.tab === 'loans'} onclick={() => setTab('loans')}>
					<Icon name="landmark" size="1.2vmin" />
					Loans
				</button>
				<button type="button" class="tab" class:active={financeState.tab === 'crypto'} onclick={() => setTab('crypto')}>
					<Icon name="coins" size="1.2vmin" />
					Crypto
				</button>
			</div>
			<div class="body">
				{#if financeState.tab === 'accounts'}
					<AccountsView />
				{:else if financeState.tab === 'loans'}
					<LoansTab />
				{:else}
					<CryptoTab />
				{/if}
			</div>
			<CreateAccountModal open={creating} onClose={() => (creating = false)} />
		{:else}
			<div class="body">
				<AtmShell />
			</div>
		{/if}

		<Toast />
	</div>
{/if}

<style>
	.panel {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		width: 52vw;
		max-width: 900px;
		height: 68vh;
		max-height: 760px;
		display: flex;
		flex-direction: column;
		background: rgba(8, 10, 13, 1);
		border: var(--border-primary);
		border-radius: var(--radius);
		overflow: hidden;
		pointer-events: auto;
	}

	.panel.atm {
		width: 30vw;
		max-width: 480px;
		height: 52vh;
		max-height: 560px;
	}

	.tabs {
		flex-shrink: 0;
		display: flex;
		gap: 0.4vw;
		padding: 0.8vh 1.4vw;
		border-bottom: var(--border-subtle);
	}

	.tab {
		display: flex;
		align-items: center;
		gap: 0.5vw;
		background: transparent;
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text-muted);
		font-family: inherit;
		font-size: 1.37vmin;
		font-weight: 600;
		padding: 0.7vh 1vw;
		cursor: pointer;
		transition: color 120ms ease, background 120ms ease, border-color 120ms ease;
	}

	.tab:hover {
		color: var(--color-text);
	}

	.tab.active {
		color: var(--color-primary-light);
		border-color: var(--color-primary);
		background: var(--color-primary-tint-soft);
	}

	.body {
		flex: 1;
		min-height: 0;
		display: flex;
	}
</style>
