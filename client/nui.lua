RegisterNUICallback("Bank:Fetch", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:GetAccounts", {}, function(accounts)
		cb({
			accounts = accounts,
		})
	end)
end)

RegisterNUICallback("Bank:Register", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:RegisterAccount", {
		type = data.type,
		name = data.name,
	}, cb)
end)

RegisterNUICallback("Bank:AddJoint", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:AddJoint", {
		account = data.account,
		target = tonumber(data.target),
	}, cb)
end)

RegisterNUICallback("Bank:RemoveJoint", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:RemoveJoint", {
		account = data.account,
		target = tonumber(data.target),
	}, cb)
end)

RegisterNUICallback("Bank:Rename", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:RenameAccount", {
		account = data.account,
		name = data.name,
	}, cb)
end)

RegisterNUICallback("Bank:Deposit", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:DoAccountAction", {
		account = data.account,
		action = "DEPOSIT",
		amount = data.amount,
		description = data.comments,
	}, function(succ, newBal)
		cb({
			state = succ,
			balance = newBal,
		})
	end)
end)

RegisterNUICallback("Bank:Withdraw", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:DoAccountAction", {
		account = data.account,
		action = "WITHDRAW",
		amount = data.amount,
		description = data.comments,
	}, function(succ, newBal)
		cb({
			state = succ,
			balance = newBal,
		})
	end)
end)

RegisterNUICallback("Bank:Transfer", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:DoAccountAction", {
		account = data.account,
		action = "TRANSFER",
		targetType = data.type,
		target = data.target,
		amount = data.amount,
		description = data.comments,
	}, function(succ, newBal)
		cb({
			state = succ,
			balance = newBal,
		})
	end)
end)

RegisterNUICallback("Bank:GetTransactions", function(data, cb)
	plsr.Callbacks:ServerCallback("Banking:GetAccountsTransactions", data, cb)
end)

-- Loans:GetLoans/Loans:Payment already existed server-side
-- (server/components/loans/callbacks.lua) but were never wired to any NUI
-- callback — no client Lua for Loans existed before this. Loans:GetLoans
-- resolves a single table {loans, creditScore}, NOT two positional args (the
-- old commented-out stub above this file used to assume the wrong shape).
RegisterNUICallback("Loans:GetLoans", function(data, cb)
	plsr.Callbacks:ServerCallback("Loans:GetLoans", {}, cb)
end)

-- Loans:Payment resolves one table on failure, or (table, refreshedLoans) on
-- success — see server/components/loans/callbacks.lua.
RegisterNUICallback("Loans:Payment", function(data, cb)
	plsr.Callbacks:ServerCallback("Loans:Payment", {
		loan = data.loan,
	}, function(result, refreshed)
		cb({
			result = result,
			refreshed = refreshed,
		})
	end)
end)

-- Crypto:GetAll already existed server-side (server/components/crypto/crypto.lua);
-- Crypto:GetWallet/Buy/Sell/Transfer are new server callbacks added in
-- server/components/crypto/callbacks.lua, thin wrappers around the existing
-- plsr.Crypto.Exchange component functions.
RegisterNUICallback("Crypto:GetAll", function(data, cb)
	plsr.Callbacks:ServerCallback("Crypto:GetAll", {}, cb)
end)

RegisterNUICallback("Crypto:GetWallet", function(data, cb)
	plsr.Callbacks:ServerCallback("Crypto:GetWallet", {}, cb)
end)

RegisterNUICallback("Crypto:Buy", function(data, cb)
	plsr.Callbacks:ServerCallback("Crypto:Buy", {
		coin = data.coin,
		amount = tonumber(data.amount),
	}, cb)
end)

RegisterNUICallback("Crypto:Sell", function(data, cb)
	plsr.Callbacks:ServerCallback("Crypto:Sell", {
		coin = data.coin,
		amount = tonumber(data.amount),
	}, cb)
end)

RegisterNUICallback("Crypto:Transfer", function(data, cb)
	plsr.Callbacks:ServerCallback("Crypto:Transfer", {
		coin = data.coin,
		target = data.target,
		amount = tonumber(data.amount),
	}, cb)
end)
