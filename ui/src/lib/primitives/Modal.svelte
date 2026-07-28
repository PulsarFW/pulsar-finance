<script lang="ts">
	import type { Snippet } from 'svelte';
	import Loader from './Loader.svelte';

	let {
		open,
		title,
		submitLabel = 'Save',
		closeLabel = 'Cancel',
		loading = false,
		onClose,
		onSubmit,
		children,
	}: {
		open: boolean;
		title: string;
		submitLabel?: string;
		closeLabel?: string;
		loading?: boolean;
		onClose: () => void;
		onSubmit?: (e: SubmitEvent) => void;
		children: Snippet;
	} = $props();
</script>

{#if open}
	<div class="backdrop" onclick={onClose} onkeydown={(e) => e.key === 'Escape' && onClose()} role="button" tabindex="-1" aria-label="Close dialog">
		<div class="dialog-shell" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.stopPropagation()} role="dialog" aria-modal="true" tabindex="-1">
			<form
				class="dialog"
				onsubmit={(e) => {
					e.preventDefault();
					onSubmit?.(e);
				}}
			>
				<div class="title">{title}</div>
				<div class="content">
					{@render children()}
				</div>
				{#if loading}<Loader text="Working" />{/if}
				<div class="actions">
					<button type="button" class="btn btn-ghost" onclick={onClose} disabled={loading}>{closeLabel}</button>
					{#if onSubmit}
						<button type="submit" class="btn btn-primary" disabled={loading}>{submitLabel}</button>
					{/if}
				</div>
			</form>
		</div>
	</div>
{/if}

<style>
	.backdrop {
		position: fixed;
		inset: 0;
		background: rgba(0, 0, 0, 0.6);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 150;
		pointer-events: auto;
	}

	.dialog-shell {
		width: 28vw;
		min-width: 340px;
		max-height: 80vh;
		overflow-y: auto;
		background: var(--color-bg-panel);
		border: var(--border-subtle);
		border-radius: var(--radius);
	}

	.dialog {
		padding: 2vh 1.6vw;
	}

	.title {
		font-family: var(--font-heading);
		font-size: 2.08vmin;
		font-weight: 600;
		color: var(--color-text);
		margin-bottom: 1.6vh;
	}

	.content {
		display: flex;
		flex-direction: column;
	}

	.actions {
		margin-top: 0.6vh;
		display: flex;
		justify-content: flex-end;
		gap: 0.8vw;
	}

	.btn {
		border: none;
		padding: 0.9vh 1.6vw;
		font-size: 1.49vmin;
		font-weight: 600;
		font-family: var(--font-body);
		cursor: pointer;
		border-radius: var(--radius);
	}

	.btn-ghost {
		background: transparent;
		color: var(--color-text-muted);
		border: var(--border-subtle);
	}

	.btn-primary {
		background: var(--color-primary);
		color: #ffffff;
	}

	.btn:disabled {
		opacity: 0.5;
		pointer-events: none;
	}
</style>
