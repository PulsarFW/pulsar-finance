return {
	Loans = {
		defaultInterestRate = 15, -- % annual interest rate for a new loan
		paymentInterval = 60 * 60 * 24 * 7, -- seconds between loan payments (weekly)
		missedPayments = {
			limit = 4, -- consecutive missed payments before a loan defaults
			interestIncrease = 2.5, -- % interest rate increase added per missed payment
			charge = 5, -- % of original loan amount charged as a late fee
		},
		loanDefaulting = {
			charge = 15, -- % of original loan amount charged when a loan defaults
		},
		maxActiveLoans = {
			default = 2, -- concurrent loan cap per player
			highCreditScore = 3, -- concurrent loan cap for players above the threshold below
			highCreditScoreThreshold = 420,
		},
		minAgeForEarlyPaymentDays = 5, -- days a loan must exist before an advance/early payment is allowed
		largeLoanCreditBonus = { perAmount = 50000, bonus = 10 }, -- extra credit score per this-much increment of loan size, on full repayment
		earlyPaymentCreditBonus = 2, -- flat credit score bonus for paying an installment before it's due
	},

	CreditScore = {
		default = 150, -- starting credit score for a new character
		min = 100,
		max = 1400,
		removal = {
			missedLoanPayment = 15, -- credit score lost per missed payment
			defaultedLoan = 35, -- credit score lost when a loan defaults
		},
		addition = {
			loanPaymentMin = 60, -- min credit score gained per on-time payment (scales up to max across the loan's remaining payments)
			loanPaymentMax = 140, -- cap on credit score gained per on-time payment
			completingLoan = 20, -- bonus credit score for fully repaying a loan
			completingLoanNoMissed = 30, -- bonus credit score for repaying a loan with zero missed payments
		},
		-- credit-score -> loan-amount multiplier curve, per loan type; higher score unlocks a bigger multiplier
		allowedLoanMultipliers = {
			vehicle = {
				{ value = 0, multiplier = 0 },
				{ value = 100, multiplier = 200 },
				{ value = 250, multiplier = 250 },
				{ value = 350, multiplier = 280 },
				{ value = 450, multiplier = 320 },
				{ value = 600, multiplier = 400 },
				{ value = 800, multiplier = 600 },
				{ value = 900, multiplier = 800 },
				{ value = 1000, multiplier = 1000 },
				{ value = 1100, multiplier = 1200 },
				{ value = 1200, multiplier = 1400 },
			},
			property = {
				{ value = 0, multiplier = 0 },
				{ value = 170, multiplier = 300 },
				{ value = 220, multiplier = 550 },
				{ value = 350, multiplier = 800 },
				{ value = 500, multiplier = 1000 },
				{ value = 800, multiplier = 1200 },
				{ value = 1000, multiplier = 1300 },
				{ value = 1200, multiplier = 1400 },
			},
		},
	},

	Banking = {
		newAccountBalance = 5000, -- starting cash balance for a new personal bank account
		actionCooldownMs = 2000, -- anti-cheat cooldown between deposit/withdraw/transfer actions (trips a Pwnzor screenshot if exceeded)
	},

	Billing = {
		maxFineAmount = 100000, -- upper limit on a single /fine command
		fineSplits = {
			finer = 0.15, -- cut of a paid fine given to whoever issued it
			police = 0.25, -- cut deposited into the issuing officer's police department account
			-- remainder goes to the government account
		},
	},

	Wallet = {
		giveCashDistance = 5.0, -- max distance to hand cash directly to another player
	},

	-- toast display durations (ms) for phone notifications sent by this resource
	Notifications = {
		bankingMs = 6000, -- deposit-received notification
		cryptoMs = 6000, -- crypto buy/sell/transfer notifications
		billingReceivedMs = 5000, -- "you were paid" notification when someone pays a bill you sent
		billingMs = 7500, -- new bill / fine received / bank charge notifications
		billingPaymentMs = 3000, -- bill payment success/fail toast
		loansMs = 7500, -- loan due / missed / defaulted notifications
		walletShowCashMs = 2500, -- "you have $X" toast
	},
}
