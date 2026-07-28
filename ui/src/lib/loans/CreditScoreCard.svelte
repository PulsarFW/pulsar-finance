<!-- shows the credit score against its real 100-1400 range, server/components/loans/config.lua's _creditScoreConfig -->
<script lang="ts">
	import { CREDIT_SCORE_MAX, CREDIT_SCORE_MIN } from '../../config';

	let { score }: { score: number } = $props();

	const pct = $derived(Math.max(0, Math.min(100, ((score - CREDIT_SCORE_MIN) / (CREDIT_SCORE_MAX - CREDIT_SCORE_MIN)) * 100)));

	const tier = $derived.by(() => {
		if (score >= 900) return { label: 'Excellent', color: 'var(--color-success)' };
		if (score >= 500) return { label: 'Good', color: 'var(--color-info)' };
		if (score >= 250) return { label: 'Fair', color: 'var(--color-warning)' };
		return { label: 'Poor', color: 'var(--color-error)' };
	});
</script>

<div class="card">
	<div class="top">
		<span class="label">Credit Score</span>
		<span class="tier" style:color={tier.color}>{tier.label}</span>
	</div>
	<div class="score">{score}</div>
	<div class="bar">
		<div class="fill" style:width={`${pct}%`} style:background={tier.color}></div>
	</div>
	<div class="range">
		<span>{CREDIT_SCORE_MIN}</span>
		<span>{CREDIT_SCORE_MAX}</span>
	</div>
</div>

<style>
	.card {
		background: rgba(230, 232, 236, 0.04);
		border: var(--border-subtle);
		border-radius: var(--radius);
		padding: 1.4vh 1.4vw;
	}

	.top {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.label {
		font-size: 1.1vmin;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.tier {
		font-size: 1.3vmin;
		font-weight: 600;
	}

	.score {
		font-size: 3.38vmin;
		font-weight: 700;
		color: var(--color-text);
		margin-top: 0.4vh;
	}

	.bar {
		margin-top: 1vh;
		height: 6px;
		border-radius: 3px;
		background: rgba(230, 232, 236, 0.1);
		overflow: hidden;
	}

	.fill {
		height: 100%;
		border-radius: 3px;
		transition: width 300ms ease;
	}

	.range {
		margin-top: 0.4vh;
		display: flex;
		justify-content: space-between;
		font-size: 1.04vmin;
		color: var(--color-text-muted);
	}
</style>
