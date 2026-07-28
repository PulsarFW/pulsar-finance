<!-- themed button reacting to whichever bank brand's accent is active via --color-primary-tint-*, not a hardcoded color -->
<script lang="ts">
	let {
		label,
		onclick,
		disabled = false,
		variant = 'default',
		type = 'button',
	}: { label: string; onclick?: () => void; disabled?: boolean; variant?: 'default' | 'danger' | 'primary'; type?: 'button' | 'submit' } = $props();
</script>

<button {type} class="action" class:danger={variant === 'danger'} class:primary={variant === 'primary'} {disabled} {onclick}>
	{label}
</button>

<style>
	.action {
		background: rgba(230, 232, 236, 0.05);
		border: var(--border-subtle);
		border-radius: var(--radius);
		color: var(--color-text);
		font-family: inherit;
		font-size: 1.37vmin;
		font-weight: 600;
		padding: 0.9vh 1.2vw;
		cursor: pointer;
		transition: color 120ms ease, border-color 120ms ease, background 120ms ease;
	}

	.action:hover:not(:disabled) {
		border-color: var(--color-primary);
		background: var(--color-primary-tint-medium);
		color: var(--color-primary-light);
	}

	.action.primary {
		border-color: var(--color-primary);
		background: var(--color-primary-tint-soft);
		color: var(--color-primary-light);
	}

	.action.primary:hover:not(:disabled) {
		background: var(--color-primary-tint-medium);
	}

	.action.danger:hover:not(:disabled) {
		border-color: rgba(217, 82, 90, 0.5);
		background: rgba(217, 82, 90, 0.14);
		color: var(--color-error);
	}

	.action:disabled {
		opacity: 0.35;
		pointer-events: none;
	}
</style>
