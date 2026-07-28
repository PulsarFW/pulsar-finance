/*
	Pulsar Finance content config.
	Server owners: for base colors/fonts, edit theme.css instead. BRAND_ACCENTS below is each bank
	brand's accent palette, applied as inline custom-property overrides once a real brand arrives from Lua (see Shell.svelte).
	Fleeca's values match theme.css's :root defaults, used as the fallback before a brand is known.
*/

export type Brand = 'fleeca' | 'maze' | 'blaineco' | 'ud';
export type AppMode = 'BANK' | 'ATM';

export interface BrandAccent {
	name: string;
	primary: string;
	primaryLight: string;
	primaryDark: string;
	borderPrimary: string;
	tintSoft: string;
	tintMedium: string;
}

export const BRAND_ACCENTS: Record<Brand, BrandAccent> = {
	fleeca: {
		name: 'Fleeca Bank',
		primary: '#2f9e52',
		primaryLight: '#5cc47f',
		primaryDark: '#1c6b37',
		borderPrimary: '1px solid rgba(47, 158, 82, 0.32)',
		tintSoft: 'rgba(47, 158, 82, 0.08)',
		tintMedium: 'rgba(47, 158, 82, 0.16)',
	},
	maze: {
		name: 'Maze Bank',
		primary: '#e0313d',
		primaryLight: '#f0757d',
		primaryDark: '#8a1f28',
		borderPrimary: '1px solid rgba(224, 49, 61, 0.32)',
		tintSoft: 'rgba(224, 49, 61, 0.08)',
		tintMedium: 'rgba(224, 49, 61, 0.16)',
	},
	blaineco: {
		name: 'Blaine County Savings',
		primary: '#8a2230',
		primaryLight: '#c15564',
		primaryDark: '#4f1119',
		borderPrimary: '1px solid rgba(138, 34, 48, 0.32)',
		tintSoft: 'rgba(138, 34, 48, 0.08)',
		tintMedium: 'rgba(138, 34, 48, 0.16)',
	},
	ud: {
		name: 'Union Depository',
		primary: '#2f6fa8',
		primaryLight: '#6ea3d6',
		primaryDark: '#1d4266',
		borderPrimary: '1px solid rgba(47, 111, 168, 0.32)',
		tintSoft: 'rgba(47, 111, 168, 0.08)',
		tintMedium: 'rgba(47, 111, 168, 0.16)',
	},
};

export type AccountType = 'personal' | 'personal_savings' | 'organization';

export function getAccountTypeLabel(type: AccountType | string): string {
	switch (type) {
		case 'personal':
			return 'Checking Account';
		case 'personal_savings':
			return 'Savings Account';
		case 'organization':
			return 'Organization Account';
		default:
			return 'Bank Account';
	}
}

export type LoanType = 'vehicle' | 'property';

export function getLoanTypeLabel(type: LoanType | string): string {
	switch (type) {
		case 'vehicle':
			return 'Vehicle Loan';
		case 'property':
			return 'Property Loan';
		default:
			return 'Asset Loan';
	}
}

export function getLoanIdentifierLabel(type: LoanType | string): string {
	switch (type) {
		case 'vehicle':
			return 'Vehicle VIN';
		case 'property':
			return 'Property ID';
		default:
			return 'Asset ID';
	}
}

// actual amount due for a full payoff right now, including current interest, real financial math not something to redesign
export function getPayoffAmount(loan: { Remaining: number; InterestRate: number }): number {
	if (loan.Remaining <= 0) return 0;
	const interestMult = (100 + loan.InterestRate) / 100;
	return Math.ceil(loan.Remaining * interestMult);
}

// amount due for the next scheduled payment, or the catch-up amount if payments have been missed
export function getNextPaymentAmount(loan: { Remaining: number; InterestRate: number; TotalPayments: number; PaidPayments: number; MissedPayments: number }): number {
	if (loan.Remaining <= 0) return 0;
	const interestMult = (100 + loan.InterestRate) / 100;
	const remainingPayments = loan.TotalPayments - loan.PaidPayments;
	let weeks = loan.MissedPayments > 1 ? loan.MissedPayments : 1;
	if (weeks > remainingPayments) weeks = remainingPayments;
	const eachPayment = loan.Remaining / remainingPayments;
	return Math.ceil(eachPayment * weeks * interestMult);
}

export const CREDIT_SCORE_MIN = 100;
export const CREDIT_SCORE_MAX = 1400;

export const CURRENCY = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
