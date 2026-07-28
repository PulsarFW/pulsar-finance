<!-- personal_savings accounts only, only the account's real Owner can add/remove joint owners -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import ActionButton from '../primitives/ActionButton.svelte';
	import Icon from '../Icon.svelte';
	import { Nui } from '../nui';
	import { financeState, toast } from '../store/finance.svelte';
	import type { Account } from '../types';

	let { open, account, onClose, onChanged }: { open: boolean; account: Account; onClose: () => void; onChanged: (owners: number[]) => void } = $props();

	const isOwner = $derived(account.Owner === financeState.character?.SID);

	let adding = $state(false);
	let target = $state('');
	let loading = $state(false);

	async function removeOwner(sid: number) {
		if (!isOwner || !account?.Permissions?.MANAGE) return;
		loading = true;
		const ok = await Nui.bankRemoveJoint(account.Account, sid);
		loading = false;
		if (ok) {
			toast.success('Joint Owner Removed');
			onChanged((account.JointOwners ?? []).filter((o) => o !== sid));
		} else {
			toast.error('Unable To Remove Joint Owner');
		}
	}

	function closeAll() {
		adding = false;
		onClose();
	}

	async function addOwner() {
		const sid = Number(target);
		if (!sid) return;
		if (sid === financeState.character?.SID) {
			toast.error('You Cannot Add Yourself As A Joint Owner');
			return;
		}
		loading = true;
		const ok = await Nui.bankAddJoint(account.Account, sid);
		loading = false;
		if (ok) {
			toast.success('Joint Owner Added');
			onChanged([...(account.JointOwners ?? []), sid]);
			target = '';
			adding = false;
		} else {
			toast.error('Unable To Add Joint Owner');
		}
	}
</script>

<Modal open={open} title={`${account.Name ?? 'Account'} Joint Owners`} closeLabel="Close" onClose={closeAll}>
	{#if (account.JointOwners ?? []).length === 0}
		<div class="empty">No Joint Owners</div>
	{:else}
		{#each account.JointOwners ?? [] as sid (sid)}
			<div class="owner-row">
				<span class="cell"><span class="label">State ID</span><span class="value">{sid}</span></span>
				{#if isOwner}
					<button type="button" class="remove" title="Remove Owner" onclick={() => removeOwner(sid)} disabled={loading}>
						<Icon name="xmark" size="1.1vmin" />
					</button>
				{/if}
			</div>
		{/each}
	{/if}
	{#if isOwner}
		<div class="add-action">
			<ActionButton label="Add Owner" variant="primary" onclick={() => (adding = true)} />
		</div>
	{/if}
</Modal>

<Modal open={adding} title={`Add Joint Owner To ${account.Name ?? 'Account'}`} submitLabel="Add" {loading} onClose={() => (adding = false)} onSubmit={addOwner}>
	<Field label="State ID" name="target" type="number" bind:value={target} required />
</Modal>

<style>
	.owner-row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0.8vh 0;
		border-bottom: var(--border-subtle);
	}

	.cell {
		display: flex;
		flex-direction: column;
	}

	.label {
		font-size: 1.04vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
	}

	.value {
		font-size: 1.49vmin;
		color: var(--color-text);
	}

	.remove {
		background: transparent;
		border: none;
		color: var(--color-error);
		cursor: pointer;
		padding: 0.5vh;
		display: flex;
	}

	.empty {
		text-align: center;
		padding: 1.6vh 0;
		color: var(--color-text-muted);
		font-size: 1.43vmin;
	}

	.add-action {
		margin-top: 1.2vh;
	}
</style>
