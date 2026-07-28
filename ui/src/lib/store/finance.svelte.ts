// single domain store: which app/brand is open (SET_APP), the player's cash (SET_DATA), the account list + selection,
// Loans/Crypto state (fetched on-demand when those tabs open, not pushed), and the toast queue

import type { AppMode, Brand } from '../../config';
import type { Account, CharacterCash, CryptoCoin, CryptoWallet, Loan } from '../types';
import { Nui } from '../nui';

export type FinanceTab = 'accounts' | 'loans' | 'crypto';

export const financeState = $state({
	hidden: true,
	app: 'BANK' as AppMode,
	brand: 'fleeca' as Brand,
	tab: 'accounts' as FinanceTab,
	character: null as CharacterCash | null,
	accounts: [] as Account[],
	accountsLoaded: false,
	selectedAccount: null as string | number | null,
	loans: [] as Loan[],
	creditScore: 0,
	loansLoaded: false,
	cryptoCoins: [] as CryptoCoin[],
	cryptoWallet: null as CryptoWallet | null,
	cryptoLoaded: false,
});

export interface Toast {
	id: number;
	kind: 'success' | 'error';
	message: string;
}

export const toastState = $state({ toasts: [] as Toast[] });

let nextToastId = 1;
export const toast = {
	success(message: string) {
		push('success', message);
	},
	error(message: string) {
		push('error', message);
	},
};

function push(kind: 'success' | 'error', message: string) {
	const id = nextToastId++;
	toastState.toasts = [...toastState.toasts, { id, kind, message }];
	setTimeout(() => dismissToast(id), 4000);
}

export function dismissToast(id: number) {
	toastState.toasts = toastState.toasts.filter((t) => t.id !== id);
}

export function handleFinanceMessage(type: string, data: Record<string, unknown>) {
	switch (type) {
		case 'SET_APP':
			financeState.app = (data.app as AppMode) ?? 'BANK';
			financeState.brand = (data.brand as Brand) ?? 'fleeca';
			financeState.hidden = false;
			financeState.tab = 'accounts';
			financeState.selectedAccount = null;
			financeState.accountsLoaded = false;
			financeState.loansLoaded = false;
			financeState.cryptoLoaded = false;
			break;
		case 'APP_HIDE':
			financeState.hidden = true;
			break;
		case 'SET_DATA':
			if (data.type === 'character') financeState.character = data.data as CharacterCash;
			break;
	}
}

export function selectAccount(account: string | number | null) {
	financeState.selectedAccount = account;
}

// shared by AccountsView (Bank) and AtmShell (ATM), both apps read the same account list
export async function refreshAccounts(): Promise<void> {
	const res = await Nui.bankFetch();
	financeState.accounts = res?.accounts ?? [];
	financeState.accountsLoaded = true;
}

export function setTab(tab: FinanceTab) {
	financeState.tab = tab;
}

export function applyLoans(loans: Loan[], creditScore: number) {
	financeState.loans = loans;
	financeState.creditScore = creditScore;
	financeState.loansLoaded = true;
}

export function applyCrypto(coins: CryptoCoin[], wallet: CryptoWallet | null) {
	financeState.cryptoCoins = coins;
	financeState.cryptoWallet = wallet;
	financeState.cryptoLoaded = true;
}
