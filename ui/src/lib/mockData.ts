// representative dev-mode data: a mixed account list, an active + missed-payment + paid-off loan so all credit-health
// states are visible, and a wallet holding both a buyable and non-buyable coin so the Buyable-gated Buy button is checkable

import type { Account, CryptoCoin, CryptoWallet, Loan, Transaction } from './types';

export const MOCK_ACCOUNTS: Account[] = [
	{ Account: 1001, Type: 'personal', Owner: 1, Balance: 4820.5, Permissions: { MANAGE: true, BALANCE: true, WITHDRAW: true, DEPOSIT: true, TRANSACTIONS: true } },
	{
		Account: 1002,
		Type: 'personal_savings',
		Owner: 1,
		Balance: 21500,
		Name: 'Rainy Day Fund',
		Permissions: { MANAGE: true, BALANCE: true, WITHDRAW: true, DEPOSIT: true, TRANSACTIONS: true },
		JointOwners: [2],
	},
	{
		Account: 1003,
		Type: 'organization',
		Owner: 1,
		Balance: 118400,
		Name: 'Los Santos Customs LLC',
		Permissions: { MANAGE: true, BALANCE: true, WITHDRAW: true, DEPOSIT: true, TRANSACTIONS: true },
	},
];

export const MOCK_TRANSACTIONS: Transaction[] = [
	{ Amount: 500, Type: 'deposit', TransactionAccount: false, Title: 'Cash Deposit', Account: 1001, Timestamp: Date.now() / 1000 - 3600, Description: 'Weekly cash-out' },
	{ Amount: 1200, Type: 'transfer', TransactionAccount: 1002, Title: 'Transfer to Savings', Account: 1001, Timestamp: Date.now() / 1000 - 86400, Description: 'Moving funds' },
	{ Amount: 200, Type: 'withdraw', TransactionAccount: false, Title: 'Cash Withdrawal', Account: 1001, Timestamp: Date.now() / 1000 - 172800, Description: 'No Description' },
];

export const MOCK_LOANS: Loan[] = [
	{
		_id: 1,
		SID: 1,
		Type: 'vehicle',
		AssetIdentifier: '1HGCM82633A004352',
		Defaulted: false,
		InterestRate: 15,
		Total: 45000,
		Remaining: 28400,
		Paid: 16600,
		DownPayment: 5000,
		TotalPayments: 20,
		PaidPayments: 9,
		MissablePayments: 4,
		MissedPayments: 0,
		TotalMissedPayments: 0,
		NextPayment: Date.now() / 1000 + 4 * 86400,
		LastPayment: Date.now() / 1000 - 3 * 86400,
		LastMissedPayment: null,
		Creation: Date.now() / 1000 - 60 * 86400,
	},
	{
		_id: 2,
		SID: 1,
		Type: 'property',
		AssetIdentifier: 'PROP-2281',
		Defaulted: false,
		InterestRate: 20,
		Total: 220000,
		Remaining: 190000,
		Paid: 30000,
		DownPayment: 20000,
		TotalPayments: 30,
		PaidPayments: 3,
		MissedPayments: 2,
		MissablePayments: 4,
		TotalMissedPayments: 2,
		NextPayment: Date.now() / 1000 - 2 * 86400,
		LastPayment: Date.now() / 1000 - 9 * 86400,
		LastMissedPayment: Date.now() / 1000 - 2 * 86400,
		Creation: Date.now() / 1000 - 20 * 86400,
	},
	{
		_id: 3,
		SID: 1,
		Type: 'vehicle',
		AssetIdentifier: 'PAID-OFF-9981',
		Defaulted: false,
		InterestRate: 15,
		Total: 18000,
		Remaining: 0,
		Paid: 18000,
		DownPayment: 2000,
		TotalPayments: 12,
		PaidPayments: 12,
		MissablePayments: 4,
		MissedPayments: 0,
		TotalMissedPayments: 0,
		NextPayment: 0,
		LastPayment: Date.now() / 1000 - 30 * 86400,
		LastMissedPayment: null,
		Creation: Date.now() / 1000 - 200 * 86400,
	},
];

export const MOCK_CREDIT_SCORE = 640;

export const MOCK_CRYPTO: CryptoCoin[] = [
	{ Name: 'Mald Coin', Short: 'MALD', Price: 250, Buyable: true, Sellable: 190 },
	{ Name: 'Vroom', Short: 'VRM', Price: 100, Buyable: false, Sellable: false },
	{ Name: 'Heist Token', Short: 'HEIST', Price: 100, Buyable: false, Sellable: false },
];

export const MOCK_WALLET: CryptoWallet = {
	WalletId: 'a1b2c',
	Holdings: { MALD: 12, HEIST: 3 },
};
