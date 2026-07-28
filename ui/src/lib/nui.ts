// outbound UI -> Lua transport, see client/nui.lua for Bank:* handlers, Loans:*/Crypto:* follow the same
// RegisterNUICallback pattern. like pulsar_admin, devValue is real representative mock data (mockData.ts),
// also the fallback if a real fetch ever throws

import type { Account, CryptoCoin, CryptoWallet, Loan, LoanPaymentResult, LoansResponse, Transaction } from './types';
import { MOCK_ACCOUNTS, MOCK_CREDIT_SCORE, MOCK_CRYPTO, MOCK_LOANS, MOCK_TRANSACTIONS, MOCK_WALLET } from './mockData';

const RESOURCE_NAME = 'pulsar_finance';

async function send(event: string, data: unknown = {}): Promise<void> {
	if (import.meta.env.DEV) return;
	try {
		await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
	} catch {
		// Expected to fail outside the actual NUI browser
	}
}

async function sendJson<T>(event: string, data: unknown, devValue: T): Promise<T> {
	if (import.meta.env.DEV) return devValue;
	try {
		const res = await fetch(`https://${RESOURCE_NAME}/${event}`, {
			method: 'post',
			headers: { 'Content-Type': 'application/json; charset=UTF-8' },
			body: JSON.stringify(data),
		});
		return (await res.json()) as T;
	} catch {
		return devValue;
	}
}

export interface DepositResult {
	state: boolean;
	balance?: number;
}

export const Nui = {
	close: () => send('Close'),

	bankFetch: () => sendJson<{ accounts: Account[] } | null>('Bank:Fetch', {}, { accounts: MOCK_ACCOUNTS }),
	// account type is always 'personal_savings', no `name` field
	bankRegister: (type: string) => sendJson<Account | false>('Bank:Register', { type }, { ...MOCK_ACCOUNTS[1], Account: Date.now() }),
	bankAddJoint: (account: string | number, target: number) => sendJson<boolean>('Bank:AddJoint', { account, target }, true),
	bankRemoveJoint: (account: string | number, target: number) => sendJson<boolean>('Bank:RemoveJoint', { account, target }, true),
	bankRename: (account: string | number, name: string) => sendJson<boolean>('Bank:Rename', { account, name }, true),
	bankDeposit: (account: string | number, amount: number, comments: string) =>
		sendJson<DepositResult>('Bank:Deposit', { account, amount, comments }, { state: true, balance: 5000 }),
	bankWithdraw: (account: string | number, amount: number, comments: string) =>
		sendJson<DepositResult>('Bank:Withdraw', { account, amount, comments }, { state: true, balance: 5000 }),
	// `type`: true = target is a state ID (their personal account), false = target is a specific account number
	bankTransfer: (account: string | number, type: boolean, target: string | number, amount: number, comments: string) =>
		sendJson<DepositResult>('Bank:Transfer', { account, type, target, amount, comments }, { state: true, balance: 5000 }),
	bankGetTransactions: (account: string | number, offset: number, perPage = 15) =>
		sendJson<{ data: Transaction[]; more: boolean } | null>('Bank:GetTransactions', { account, offset, perPage }, { data: MOCK_TRANSACTIONS, more: false }),

	loansGetLoans: () => sendJson<LoansResponse | false>('Loans:GetLoans', {}, { loans: MOCK_LOANS, creditScore: MOCK_CREDIT_SCORE }),
	loansPayment: (loan: number) =>
		sendJson<{ result: LoanPaymentResult; refreshed?: LoansResponse }>(
			'Loans:Payment',
			{ loan },
			{ result: { success: true, paidOff: false, paymentAmount: 1200, creditIncrease: 8 }, refreshed: { loans: MOCK_LOANS, creditScore: MOCK_CREDIT_SCORE + 8 } },
		),

	cryptoGetAll: () => sendJson<CryptoCoin[]>('Crypto:GetAll', {}, MOCK_CRYPTO),
	cryptoGetWallet: () => sendJson<CryptoWallet | false>('Crypto:GetWallet', {}, MOCK_WALLET),
	cryptoBuy: (coin: string, amount: number) => sendJson<boolean>('Crypto:Buy', { coin, amount }, true),
	cryptoSell: (coin: string, amount: number) => sendJson<boolean>('Crypto:Sell', { coin, amount }, true),
	cryptoTransfer: (coin: string, target: string, amount: number) => sendJson<boolean>('Crypto:Transfer', { coin, target, amount }, true),
};

export type { Loan };
