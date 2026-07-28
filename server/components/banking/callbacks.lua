local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _actionCooldowns = {}

function RegisterBankingCallbacks()
	plsr.Callbacks:RegisterServerCallback("Finance:Paycheck", function(source, data, cb)
		plsr.State:Player(source).gettingPaycheck = true
		local char = plsr.Fetch:CharacterSource(source)

		local salary = char:GetData("Salary") or {}
		local amt = 0
		local mts = 0
		for k, v in pairs(salary) do
			amt = amt + v.total
			mts = mts + v.minutes
		end

		if amt > 0 then
			char:SetData("Salary", false)
			plsr.Banking.Balance:Deposit(plsr.Banking.Accounts:GetPersonal(char:GetData("SID")).Account, amt, {
				type = 'paycheck',
				title = "Paycheck",
				description = string.format('Paycheck For %s Minutes Worked', mts),
				data = salary
			})
		end

		cb({
			total = amt,
			minutes = mts,
		})
		plsr.State:Player(source).gettingPaycheck = false
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:RegisterAccount", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)

		if char ~= nil then
			if data.type == "personal_savings" then
				local acc = plsr.Banking.Accounts:CreatePersonalSavings(char:GetData("SID"))
				acc.Permissions = {
					MANAGE = true,
					BALANCE = true,
					WITHDRAW = true,
					DEPOSIT = true,
					TRANSACTIONS = true,
				}
				cb(acc)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:RenameAccount", function(source, data, cb)
        local char = plsr.Fetch:CharacterSource(source)
        if not char then return cb(false) end

        local accountData = plsr.Banking.Accounts:Get(data.account)
        if not accountData then return cb(false) end

        if not HasBankAccountPermission(source, accountData, "MANAGE", char:GetData("SID")) then
            return cb(false)
        end

        if accountData.Type == "organization" then
            return cb(false)
        end

        local success = MySQL.update.await("UPDATE bank_accounts SET name = ? WHERE account = ?", {
            data.name,
            data.account
        })

        cb(success)
    end)

	plsr.Callbacks:RegisterServerCallback("Banking:AddJoint", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data?.target > 0 then
			local p = promise.new()
			plsr.Database:Single("SELECT `account`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { data.target }, function(success, row)
				if not success or row == nil then
					p:resolve(false)
					return
				end

				local ok, tChar = pcall(json.decode, row.data)
				if ok and type(tChar) == "table" then
					tChar.User = row.account
					if tChar.User == char:GetData("User") then
						plsr.Logger:Info("Billing", string.format("%s %s (%s) [%s] Tried Adding Their Other Character (SID: %s) To a Joint Bank Account (Account: %s).", char:GetData("First"), char:GetData("Last"), char:GetData("SID"), char:GetData("User"), tChar.SID, data.account), {
							console = true,
							file = true,
							database = true,
							discord = {
								embed = true,
								type = 'info',
								webhook = GetConvar('discord_log_webhook', ''),
							}
						})

						p:resolve(false)
					else
						p:resolve(true)
					end
				else
					p:resolve(false)
				end
			end)

			local canAdd = Citizen.Await(p)
			if canAdd then
				cb(plsr.Banking.Accounts:AddPersonalSavingsJointOwner(data.account, data.target))
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:RemoveJoint", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			cb(plsr.Banking.Accounts:RemovePersonalSavingsJointOwner(data.account, data.target))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:GetAccounts", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			local SID = char:GetData("SID")

			local eQry = "SELECT account, type, job, workplace, jobPermissions FROM bank_accounts_permissions WHERE (type = ? AND jointOwner = ?)"

			local params = {
				1,
				tostring(SID)
			}

			local charJobs = char:GetData("Jobs") or {}
			for k, v in ipairs(charJobs) do
				if v.Workplace and v.Workplace.Id then
					eQry = eQry .. " OR (type = ? AND job = ? AND workplace = ?)"
					table.insert(params, 0)
					table.insert(params, v.Id)
					table.insert(params, v.Workplace.Id)
				end

				eQry = eQry .. " OR (type = ? AND job = ? AND workplace = ?)"
				table.insert(params, 0)
				table.insert(params, v.Id)
				table.insert(params, "")
			end

			local pData = MySQL.query.await(eQry, params)

			local jobBankAccounts = {}
			local jobBankPerms = {}

			for k, v in ipairs(pData) do
				if v.type == 0 and v.job then
					if not jobBankPerms[v.account] then
						jobBankPerms[v.account] = { v }
					else
						table.insert(jobBankPerms[v.account], v)
					end

					table.insert(jobBankAccounts, v.account)
				elseif v.type == 1 then
					table.insert(jobBankAccounts, v.account)
				end
			end

			local qry = "SELECT account as Account, balance as Balance, type as Type, owner as Owner, name as Name FROM bank_accounts WHERE (type = ? AND owner = ?) OR (type = ? AND owner = ?)"
			if jobBankAccounts and #jobBankAccounts > 0 then
				qry = string.format("SELECT account as Account, balance as Balance, type as Type, owner as Owner, name as Name FROM bank_accounts WHERE account IN (%s) OR (type = ? AND owner = ?) OR (type = ? AND owner = ?)", table.concat(jobBankAccounts, ","))
			end

			local availableAccounts = MySQL.query.await(qry, {
				"personal",
				tostring(SID),
				"personal_savings",
				tostring(SID)
			})

			local jointOwnerStuff = {}

			for k, v in ipairs(availableAccounts) do
				if v.Type == "personal_savings" and v.Owner == tostring(SID) then
					table.insert(jointOwnerStuff, v.Account)
				end
			end

			local jointOwnerData = {}
			if #jointOwnerStuff > 0 then
				local jO = MySQL.query.await(string.format("SELECT account, jointOwner FROM bank_accounts_permissions WHERE account IN (%s) AND type = ?", table.concat(jointOwnerStuff, ",")), {
					1
				})

				for k, v in ipairs(jO) do
					if not jointOwnerData[v.account] then
						jointOwnerData[v.account] = { v.jointOwner }
					else
						table.insert(jointOwnerData[v.account], v.jointOwner)
					end
				end
			end

			local availableAccountsData = {}
			local accountTransactionData = {}

			for _, account in ipairs(availableAccounts) do
				if account.Type == "personal" then
					account.Permissions = {
						MANAGE = true,
						BALANCE = true,
						WITHDRAW = true,
						DEPOSIT = true,
						TRANSACTIONS = true,
					}
					table.insert(availableAccountsData, account)
				elseif account.Type == "personal_savings" then
					account.Permissions = {
						MANAGE = account.Owner == tostring(SID),
						BALANCE = true,
						WITHDRAW = true,
						DEPOSIT = true,
						TRANSACTIONS = true,
					}
					account.JointOwners = jointOwnerData[account.Account] or {}

					table.insert(availableAccountsData, account)
				elseif account.Type == "organization" then
					local jPData = jobBankPerms[account.Account]
					if jPData then
						-- an account can have more than one job/workplace grant row - evaluate all of
						-- them and union the results instead of stopping at the first one that resolves
						-- any permissions, or an owner match later in the list would never be reached
						local resolvedPermissions = nil

						for _, job in ipairs(jPData) do
							local workplace = false
							if job.workplace and job.workplace ~= "" and #job.workplace > 0 then
								workplace = job.workplace
							end
							local jobPermissions = plsr.Jobs.Permissions:GetPermissionsFromJob(
								source,
								job.job,
								workplace
							)

							if jobPermissions then
								if plsr.Jobs.Permissions:IsOwner(source, job.job) then
									-- owners bypass the BANK_ACCOUNT_* permission mapping entirely, and beat any other grant
									resolvedPermissions = {
										MANAGE = true,
										WITHDRAW = true,
										DEPOSIT = true,
										TRANSACTIONS = true,
										BILL = true,
										BALANCE = true,
									}
									break
								end

								resolvedPermissions = resolvedPermissions or {}
								local permList = json.decode(job.jobPermissions or "{}")
								for perm, jobPerm in pairs(permList) do
									if jobPermissions[jobPerm] then
										resolvedPermissions[perm] = true
									elseif resolvedPermissions[perm] == nil then
										resolvedPermissions[perm] = false
									end
								end
							end
						end

						-- an empty table is still truthy in Lua - only surface the account if at least one permission actually came out true
						local hasAnyPermission = false
						if resolvedPermissions then
							for _, granted in pairs(resolvedPermissions) do
								if granted then
									hasAnyPermission = true
									break
								end
							end
						end

						if hasAnyPermission then
							account.Permissions = resolvedPermissions
							table.insert(availableAccountsData, account)
						end
					end
				end
			end

			cb(availableAccountsData, PENDING_BILLS[SID])
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:GetAccountsTransactions", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data?.account and data?.perPage then
			local offset = data?.offset
			if data?.page then
				offset = data.perPage * (data.page - 1)
			end

			local transactions = MySQL.query.await("SELECT type as Type, account as Account, title as Title, timestamp as Timestamp, amount as Amount, description as Description FROM bank_accounts_transactions WHERE account = ? ORDER BY timestamp DESC LIMIT ? OFFSET ?", {
				data.account,
				data.perPage + 1,
				offset
			})

			local pages = data.page or 1
			local isMore = false
			if #transactions > data.perPage then
				table.remove(transactions)

				pages += 1
				isMore = true
			end

			cb({
				data = transactions,
				pages = pages,
				more = isMore,
			})
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Banking:DoAccountAction", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		local SID = char:GetData("SID")
		local account, action = data.account, data.action
		local accountData = plsr.Banking.Accounts:Get(account)
		if accountData then
			if _actionCooldowns[source] and _actionCooldowns[source] > GetGameTimer() then
				plsr.Logger:Warn("Pwnzor", string.format("%s %s (%s) Triggered 2 Bank Account Actions in 2 Seconds They Are Probably Cheating (%s)", char:GetData("First"), char:GetData("Last"), char:GetData("SID"), json.encode(data)), {
					console = true,
					file = false,
					database = true,
					discord = {
						embed = true,
						type = 'error',
						webhook = GetConvar('discord_pwnzor_webhook', ''),
					}
				}, {
					data = data
				})
				plsr.Pwnzor:Screenshot(char:GetData("SID"), "Bank Account Actions Cooldown Exceeded")

				cb(false)
				return
			end

			_actionCooldowns[source] = GetGameTimer() + config.Banking.actionCooldownMs

			if action == "WITHDRAW" then
				local withdrawAmount = tonumber(data.amount)
				if
					withdrawAmount
					and withdrawAmount > 0
					and accountData.Balance >= withdrawAmount
					and HasBankAccountPermission(source, accountData, action, SID)
				then
					local wSucc = plsr.Banking.Balance:Withdraw(accountData.Account, withdrawAmount, {
						type = "withdraw",
						title = "Cash Withdrawal",
						description = data.description or "No Description",
						transactionAccount = false,
						data = {
							character = SID,
						},
					})

					if wSucc then
						plsr.Wallet:Modify(source, withdrawAmount, true)
						cb(true, plsr.Banking.Balance:Get(accountData.Account))
						return
					end
				end
			elseif action == "DEPOSIT" then
				local depositAmount = tonumber(data.amount)
				if
					depositAmount
					and depositAmount > 0
					and HasBankAccountPermission(source, accountData, action, SID)
				then
					if plsr.Wallet:Modify(source, -depositAmount, true) then
						local dSucc = plsr.Banking.Balance:Deposit(accountData.Account, depositAmount, {
							type = "deposit",
							title = "Cash Deposit",
							description = data.description or "No Description",
							transactionAccount = false,
							data = {
								character = SID,
							},
						})

						if dSucc then
							cb(true, plsr.Banking.Balance:Get(accountData.Account))
							return
						end
					end
				end
			elseif action == "TRANSFER" then
				local transferAmount = tonumber(data.amount)
				local targetAccount = false
				if data.targetType then
					targetAccount = plsr.Banking.Accounts:GetPersonal(data.target)
				else
					targetAccount = plsr.Banking.Accounts:Get(tonumber(data.target))
				end

				if not targetAccount then
					plsr.Logger:Warn("Banking", string.format("Transfer failed: no %s found for target '%s'", data.targetType and "personal account (state ID)" or "account number", tostring(data.target)))
				elseif not HasBankAccountPermission(source, accountData, "WITHDRAW", SID) then
					plsr.Logger:Warn("Banking", string.format("Transfer failed: %s lacks WITHDRAW permission on account %s", SID, accountData.Account))
				end

				if transferAmount and transferAmount > 0 and targetAccount then
					if
						accountData.Balance >= transferAmount
						and HasBankAccountPermission(source, accountData, "WITHDRAW", SID)
					then
						local p = promise.new()

						if targetAccount.Type == "personal" or targetAccount.Type == "personal_savings" then
							plsr.Database:Single("SELECT `account`, `data` FROM `characters` WHERE `sid` = ? AND `deleted` = 0", { tonumber(targetAccount.Owner) }, function(success, row)
								if not success or row == nil then
									p:resolve(false)
									return
								end

								local ok, tChar = pcall(json.decode, row.data)
								if ok and type(tChar) == "table" then
									tChar.User = row.account
									if tChar.User == char:GetData("User") and tChar.SID ~= char:GetData("SID") then
										plsr.Logger:Info("Billing", string.format("%s %s (%s) [%s] Tried Bank Transferring to their other character (SID: %s, Account: %s).", char:GetData("First"), char:GetData("Last"), char:GetData("SID"), char:GetData("User"), tChar.SID, targetAccount.Account), {
											console = true,
											file = true,
											database = true,
											discord = {
												embed = true,
												type = 'info',
												webhook = GetConvar('discord_log_webhook', ''),
											}
										})
	
										p:resolve(false)
									else
										p:resolve(true)
									end
								else
									p:resolve(false)
								end
							end)
						else
							p:resolve(true)
						end

						local canTransfer = Citizen.Await(p)

						if canTransfer then
							local success = plsr.Banking.Balance:Withdraw(accountData.Account, transferAmount, {
								type = "transfer",
								title = "Outgoing Bank Transfer",
								description = string.format(
									"Transfer to Account: %s.%s",
									targetAccount.Account,
									(data.description and (" Description: " .. data.description) or "")
								),
								data = {
									character = SID,
								},
							})
	
							if success then
								local success2 = plsr.Banking.Balance:Deposit(targetAccount.Account, transferAmount, {
									type = "transfer",
									title = "Incoming Bank Transfer",
									description = string.format(
										"Transfer from Account: %s.%s",
										accountData.Account,
										(data.description and (" Description: " .. data.description) or "")
									),
									transactionAccount = accountData.Account,
									data = {
										character = SID,
									},
								})
								cb(success2)
								return
							end
						end
					end
				end
			end
		end
		cb(false)
	end)
end
