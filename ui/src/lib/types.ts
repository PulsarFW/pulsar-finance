
export interface AccountPermissions {
	MANAGE: boolean;
	BALANCE: boolean;
	WITHDRAW: boolean;
	DEPOSIT: boolean;
	TRANSACTIONS: boolean;
}

export type AccountType = 'personal' | 'personal_savings' | 'organization';

export interface Account {
	Account: string | number;
	Type: AccountType;
	Owner: number;
	Balance: number;
	Name?: string;
	Permissions?: AccountPermissions;
	/** state IDs of joint owners, personal_savings accounts only */
	JointOwners?: number[];
}

// fine/fine_profit/bill/paycheck come from other resources posting to the same log, deposit/withdraw/transfer are the only ones this UI creates
export type TransactionType = 'deposit' | 'withdraw' | 'transfer' | 'fine' | 'fine_profit' | 'bill' | 'paycheck';

export interface Transaction {
	Amount: number;
	Type: TransactionType;
	/** The other account's id for a transfer, false otherwise */
	TransactionAccount: string | number | false;
	Title: string;
	Data?: { character?: number };
	Account: string | number;
	/** Unix seconds */
	Timestamp: number;
	Description: string;
}

export interface CharacterCash {
	ID: number;
	SID: number;
	First: string;
	Last: string;
	Cash: number;
}

export interface Loan {
	_id: number;
	SID: number;
	Type: 'vehicle' | 'property';
	AssetIdentifier: string;
	Defaulted: boolean;
	InterestRate: number;
	Total: number;
	Remaining: number;
	Paid: number;
	DownPayment: number;
	TotalPayments: number;
	PaidPayments: number;
	MissablePayments: number;
	MissedPayments: number;
	TotalMissedPayments: number;
	/** Unix seconds */
	NextPayment: number;
	LastPayment: number;
	LastMissedPayment: number | null;
	Creation: number;
}

export interface LoansResponse {
	loans: Loan[];
	creditScore: number;
}

export interface LoanPaymentResult {
	success: boolean;
	message?: string;
	paidOff?: boolean;
	paymentAmount?: number;
	creditIncrease?: number;
}

export interface CryptoCoin {
	Name: string;
	Short: string;
	Price: number;
	Buyable: boolean;
	/** Truthy = sellable, and the per-unit sell price when it is */
	Sellable: boolean | number;
}

export interface CryptoWallet {
	WalletId: string;
	Holdings: Record<string, number>;
}
