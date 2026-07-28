<!-- hand-picks a curated icon set covering the tab bar, account actions, and toast/status glyphs -->
<script lang="ts">
	import {
		faArrowDown,
		faArrowUp,
		faChevronLeft,
		faChevronRight,
		faCircleCheck,
		faCircleExclamation,
		faCoins,
		faCopy,
		faCreditCard,
		faLandmark,
		faPen,
		faPlus,
		faRightLeft,
		faTriangleExclamation,
		faUserGroup,
		faWallet,
		faXmark,
		type IconDefinition,
	} from '@fortawesome/free-solid-svg-icons';

	const ICONS: Record<string, IconDefinition> = {
		wallet: faWallet,
		landmark: faLandmark,
		coins: faCoins,
		xmark: faXmark,
		plus: faPlus,
		'right-left': faRightLeft,
		'arrow-down': faArrowDown,
		'arrow-up': faArrowUp,
		pen: faPen,
		'user-group': faUserGroup,
		'circle-check': faCircleCheck,
		'circle-exclamation': faCircleExclamation,
		copy: faCopy,
		'credit-card': faCreditCard,
		'triangle-exclamation': faTriangleExclamation,
		'chevron-left': faChevronLeft,
		'chevron-right': faChevronRight,
	};

	let { name, size = '1em' }: { name: string; size?: string } = $props();

	const icon = $derived(ICONS[name] ?? faCircleExclamation);
	const path = $derived(icon.icon[4] as string);
	const viewBox = $derived(`0 0 ${icon.icon[0]} ${icon.icon[1]}`);
</script>

<svg {viewBox} width={size} height={size} fill="currentColor" aria-hidden="true">
	<path d={path} />
</svg>
