<!-- organization accounts can't be renamed here, this is also where a player gives a new account its first nickname -->
<script lang="ts">
	import Modal from '../primitives/Modal.svelte';
	import Field from '../primitives/Field.svelte';
	import { Nui } from '../nui';
	import { toast } from '../store/finance.svelte';
	import type { Account } from '../types';

	let { open, account, onClose, onSuccess }: { open: boolean; account: Account; onClose: () => void; onSuccess: (name: string) => void } = $props();

	let name = $state('');
	let loading = $state(false);

	$effect(() => {
		if (open) name = account.Name ?? '';
	});

	async function submit() {
		if (!name.trim()) return;
		loading = true;
		const ok = await Nui.bankRename(account.Account, name.trim());
		loading = false;
		if (ok) {
			toast.success('Account Renamed');
			onSuccess(name.trim());
			onClose();
		} else {
			toast.error('Unable To Rename Account');
		}
	}
</script>

<Modal open={open && account.Type !== 'organization' && !!account?.Permissions?.MANAGE} title={`Rename ${account.Name ?? 'Account'}`} submitLabel="Save" {loading} {onClose} onSubmit={submit}>
	<Field label="Account Nickname" name="name" bind:value={name} required />
</Modal>
