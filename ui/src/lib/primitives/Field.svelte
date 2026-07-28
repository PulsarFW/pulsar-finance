<!-- labeled text/number input, used by the Deposit/Withdraw/Transfer/Rename/Create-Account forms -->
<script lang="ts">
	let {
		label,
		name,
		type = 'text',
		value = $bindable(''),
		required = false,
		disabled = false,
		placeholder,
		min,
		step,
	}: {
		label: string;
		name: string;
		type?: 'text' | 'number';
		value?: string | number;
		required?: boolean;
		disabled?: boolean;
		placeholder?: string;
		min?: number;
		step?: number;
	} = $props();
</script>

<label class="field">
	<span class="label">{label}</span>
	<input class="input" {name} {type} bind:value {required} {disabled} {placeholder} {min} {step} autocomplete="off" />
</label>

<style>
	.field {
		display: block;
		margin-bottom: 1.2vh;
	}

	.label {
		display: block;
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
		margin-bottom: 0.5vh;
	}

	.input {
		width: 100%;
		background: rgba(230, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.56vmin;
		padding: 0.9vh 0.9vw;
		transition: border-color 120ms ease;
	}

	.input:focus {
		outline: none;
		border-color: var(--color-primary);
	}

	.input:disabled {
		opacity: 0.5;
	}
</style>
