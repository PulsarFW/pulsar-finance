local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_BANKING = {
	Accounts = {
		Get = function(self, accountNumber)
			return MySQL.single.await("SELECT account as Account, balance as Balance, type as Type, owner as Owner, name as Name FROM bank_accounts WHERE account = ?", {
				accountNumber
			})
		end,
		CreatePersonal = function(self, ownerSID)
			local hasAccount = plsr.Banking.Accounts:GetPersonal(ownerSID)
			if hasAccount then
				return hasAccount
			end

			local acc = CreateBankAccount("personal", tostring(ownerSID), config.Banking.newAccountBalance)
			if acc then
				return plsr.Banking.Accounts:Get(acc)
			end
			return false
		end,
		GetPersonal = function(self, ownerSID)
			return MySQL.single.await("SELECT account as Account, balance as Balance, type as Type, owner as Owner, name as Name FROM bank_accounts WHERE type = ? AND owner = ?", {
				"personal",
				tostring(ownerSID)
			})
		end,
		CreatePersonalSavings = function(self, ownerSID)
			local acc = CreateBankAccount("personal_savings", tostring(ownerSID), 0)
			if acc then
				local data = plsr.Banking.Accounts:Get(acc)
				data.JointOwners = {}
				return data
			end
			return false
		end,
		AddPersonalSavingsJointOwner = function(self, accountId, jointOwnerSID)
			local account = MySQL.single.await("SELECT account, type FROM bank_accounts WHERE type = ? AND account = ?", {
				"personal_savings",
				accountId
			})

			if account then
				local existing = MySQL.single.await("SELECT jointOwner FROM bank_accounts_permissions WHERE account = ? AND jointOwner = ?", {
					accountId,
					tostring(jointOwnerSID)
				})

				if not existing then
					return MySQL.insert.await("INSERT INTO bank_accounts_permissions (account, type, jointOwner) VALUES (?, ?, ?)", {
						accountId,
						1,
						tostring(jointOwnerSID)
					})
				end
			end
		end,
		RemovePersonalSavingsJointOwner = function(self, accountId, jointOwnerSID)
			return MySQL.query.await("DELETE FROM bank_accounts_permissions WHERE account = ? AND type = ? AND jointOwner = ?", {
				accountId,
				1,
				tostring(jointOwnerSID)
			})
		end,
		GetOrganization = function(self, accountId)
			return MySQL.single.await("SELECT account as Account, balance as Balance, type as Type, owner as Owner, name as Name FROM bank_accounts WHERE type = ? AND owner = ?", {
				"organization",
				accountId
			})
		end,
	},
	Balance = {
		Get = function(self, accountNumber)
			local account = plsr.Banking.Accounts:Get(accountNumber)
			if account then
				return account.Balance
			end
			return false
		end,
		Has = function(self, accountNumber, amount)
			local balance = plsr.Banking.Balance:Get(accountNumber)
			if balance then
				return balance >= amount
			end
			return false
		end,
		Deposit = function(self, accountNumber, amount, transactionLog, skipPhoneNoti)
			if amount and amount > 0 then
				local u = MySQL.query.await("UPDATE bank_accounts SET balance = balance + ? WHERE account = ?", {
					math.floor(amount),
					accountNumber
				})

				if u and u.affectedRows > 0 then
					if transactionLog then
						plsr.Banking.TransactionLogs:Add(
							accountNumber,
							transactionLog.type,
							math.floor(amount),
							transactionLog.title,
							transactionLog.description,
							transactionLog.transactionAccount,
							transactionLog.data
						)
	
						if transactionLog.title ~= "Cash Deposit" then
							local acct = plsr.Banking.Accounts:Get(accountNumber)
							if acct ~= nil then
								if acct.Type == "personal" or acct.Type == "personal_savings" then
									local p = plsr.Fetch:SID(tonumber(acct.Owner))
									if p ~= nil and not skipPhoneNoti then
										plsr.Phone.Notification:Add(
											p:GetData("Source"),
											"Received A Deposit",
											string.format("$%s Deposited Into %s", math.floor(amount), acct.Name),
											os.time(),
											config.Notifications.bankingMs,
											"bank",
											{}
										)
									end

									-- if acct.Type == "personal_savings" then
									-- 	local jO = MySQL.query.await("SELECT jointOwner FROM bank_accounts_permissions WHERE account = ? AND type = ?", {
									-- 		acct.Account,
									-- 		1
									-- 	})

									-- 	if jO and #jO > 0 then
									-- 		for k, v in ipairs(jO) do
									-- 			local char = Fetch:CharacterData("SID", tonumber(v.jointOwner))
									-- 			if char ~= nil then
									-- 				Phone.Notification:Add(
									-- 					char:GetData("Source"),
									-- 					"Received A Deposit",
									-- 					string.format(
									-- 						"$%s Deposited Into %s",
									-- 						math.floor(amount),
									-- 						acct.Name
									-- 					),
									-- 					os.time(),
									-- 					6000,
									-- 					"bank",
									-- 					{}
									-- 				)
									-- 			end
									-- 		end
									-- 	end
									-- end
								end
							end
						end
					end
					return true
				end
			end
			return false
		end,
		Withdraw = function(self, accountNumber, amount, transactionLog)
			if amount and amount > 0 then
				local u = MySQL.query.await("UPDATE bank_accounts SET balance = balance - ? WHERE account = ?", {
					math.floor(amount),
					accountNumber
				})

				if u and u.affectedRows > 0 then
					if transactionLog then
						plsr.Banking.TransactionLogs:Add(
							accountNumber,
							transactionLog.type,
							-(math.floor(amount)),
							transactionLog.title,
							transactionLog.description,
							transactionLog.transactionAccount,
							transactionLog.data
						)
					end

					return true
				end
			end
			return false
		end,
		-- Withdraw But Checks If Has Balance
		Charge = function(self, accountNumber, amount, transactionLog)
			if plsr.Banking.Balance:Has(accountNumber, (math.floor(amount))) then
				return plsr.Banking.Balance:Withdraw(accountNumber, (math.floor(amount)), transactionLog)
			end
			return false
		end,
	},
	TransactionLogs = {
		Add = function(self, accountNumber, tType, amount, title, description, transactionAccount, data)
			if type(data) ~= "table" then
				data = { data = data }
			end

			data.transactionAccount = transactionAccount

			MySQL.single.await("INSERT INTO bank_accounts_transactions (type, account, amount, title, description, data) VALUES (?, ?, ?, ?, ?, ?)", {
				tType,
				accountNumber,
				math.floor(amount),
				title,
				description,
				json.encode(data)
			})
		end,
	},
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Banking", _BANKING)
end)
