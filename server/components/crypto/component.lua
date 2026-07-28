local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_cryptoCoins = {}

_CRYPTO = {
	Coin = {
		Create = function(self, name, acronym, price, buyable, sellable)
			if not plsr.Crypto.Coin:Get(acronym) then
				table.insert(_cryptoCoins, {
					Name = name,
					Short = acronym,
					Price = price,
					Buyable = buyable,
					Sellable = sellable,
				})
			else
				for k, v in ipairs(_cryptoCoins) do
					if v.Short == acronym then
						_cryptoCoins[k] = {
							Name = name,
							Short = acronym,
							Price = price,
							Buyable = buyable,
							Sellable = sellable,
						}
						return
					end
				end
			end
		end,
		Get = function(self, acronym)
			for k, v in ipairs(_cryptoCoins) do
				if v.Short == acronym then
					return v
				end
			end

			return nil
		end,
		GetAll = function(self)
			return _cryptoCoins
		end,
	},
	Has = function(self, source, coin, amt)
		local char = plsr.Fetch:CharacterSource(source)
		if char ~= nil then
			local crypto = char:GetData("Crypto") or {}
			return crypto[coin] ~= nil and crypto[coin] >= amt
		else
			return false
		end
	end,
	Exchange = {
		IsListed = function(self, coin)
			for k, v in ipairs(_cryptoCoins) do
				if v.Short == coin then
					return true
				end
			end
			return false
		end,
		Buy = function(self, coin, target, amount)
			if plsr.Crypto.Exchange:IsListed(coin) then
				local char = plsr.Fetch:SID(target)
				if char ~= nil then
					local acc = plsr.Banking.Accounts:GetPersonal(char:GetData("SID"))
					local coinData = plsr.Crypto.Coin:Get(coin)
					if acc.Balance >= (coinData.Price * amount) then
						if
							plsr.Banking.Balance:Withdraw(acc.Account, (coinData.Price * amount), {
								type = "withdraw",
								title = "Crypto Purchase",
								description = string.format("Bought %s $%s", amount, coin),
								transactionAccount = false,
								data = {
									character = char:GetData("SID"),
								},
							})
						then
							plsr.Phone.Notification:Add(
								char:GetData("Source"),
								"Crypto Purchase",
								string.format("You Bought %s $%s", amount, coin),
								os.time(),
								config.Notifications.cryptoMs,
								"crypto",
								{}
							)
							return plsr.Crypto.Exchange:Add(coin, char:GetData("CryptoWallet"), amount)
						else
							return false
						end
					else
						plsr.Phone.Notification:Add(
							char:GetData("Source"),
							"Crypto Purchase",
							"Insufficient Funds",
							os.time(),
							config.Notifications.cryptoMs,
							"crypto",
							{}
						)
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end,
		Sell = function(self, coin, target, amount)
			if plsr.Crypto.Exchange:IsListed(coin) then
				local char = plsr.Fetch:SID(target)
				if char ~= nil then
					local acc = plsr.Banking.Accounts:GetPersonal(char:GetData("SID"))
					local coinData = plsr.Crypto.Coin:Get(coin)

					if coinData.Sellable then
						if plsr.Crypto.Exchange:Remove(coin, char:GetData("CryptoWallet"), amount, true) then
							return plsr.Banking.Balance:Deposit(acc.Account, (coinData.Sellable * amount), {
								type = "deposit",
								title = "Crypto Sale",
								description = string.format("Sold %s $%s", amount, coin),
								transactionAccount = false,
								data = {
									character = char:GetData("SID"),
								},
							})
						else
							return false
						end
					else
						return false
					end
				else
					return false
				end
			else
				return false
			end
		end,
		Add = function(self, coin, target, amount, skipAlert)
			local char = plsr.Fetch:CharacterData("CryptoWallet", target)
			if char ~= nil then
				local crypto = char:GetData("Crypto") or {}
				if crypto[coin] == nil then
					crypto[coin] = 0
				end

				crypto[coin] = crypto[coin] + amount
				char:SetData("Crypto", crypto)

				if not skipAlert then
					plsr.Phone.Notification:Add(
						char:GetData("Source"),
						"Received Crypto",
						string.format("You Received %s $%s", amount, coin),
						os.time(),
						config.Notifications.cryptoMs,
						"crypto",
						{}
					)
				end

				return true
			else
				local p = promise.new()
				local path = "$.Crypto." .. coin
				plsr.Database:Update(
					"UPDATE `characters` SET `data` = JSON_SET(`data`, ?, COALESCE(JSON_EXTRACT(`data`, ?), 0) + ?) WHERE `crypto_wallet` = ?",
					{ path, path, amount, target },
					function(success)
						p:resolve(success)
					end
				)

				return Citizen.Await(p)
			end
		end,
		Remove = function(self, coin, target, amount, skipAlert)
			local p = promise.new()
			local char = plsr.Fetch:CharacterData("CryptoWallet", target)
			if char ~= nil then
				local crypto = char:GetData("Crypto") or {}

				if crypto[coin] == nil then
					crypto[coin] = 0
				end

				if crypto[coin] >= amount then
					crypto[coin] = crypto[coin] - amount
					char:SetData("Crypto", crypto)

					if not skipAlert then
						plsr.Phone.Notification:Add(
							char:GetData("Source"),
							"Crypto Purchase",
							string.format("You Paid %s $%s", amount, coin),
							os.time(),
							config.Notifications.cryptoMs,
							"crypto",
							{}
						)
					end

					p:resolve(true)
				else
					p:resolve(false)
				end
			else
				plsr.Database:Single("SELECT `data` FROM `characters` WHERE `crypto_wallet` = ?", { target }, function(success, row)
					if not success or row == nil then
						p:resolve(false)
						return
					end

					local ok, decoded = pcall(json.decode, row.data)
					if not ok or type(decoded) ~= "table" or not decoded.Crypto or (decoded.Crypto[coin] or 0) < amount then
						p:resolve(false)
						return
					end

					local path = "$.Crypto." .. coin
					plsr.Database:Update(
						"UPDATE `characters` SET `data` = JSON_SET(`data`, ?, COALESCE(JSON_EXTRACT(`data`, ?), 0) - ?) WHERE `crypto_wallet` = ?",
						{ path, path, amount, target },
						function(updateSuccess)
							p:resolve(updateSuccess)
						end
					)
				end)
			end

			return Citizen.Await(p)
		end,
		Transfer = function(self, coin, sender, target, amount)
			local char = plsr.Fetch:SID(sender)
			if char then
				if char:GetData("CryptoWallet") ~= target then
					local tChar = plsr.Fetch:CharacterData("CryptoWallet", target)

					if tChar or DoesCryptoWalletExist(target) then
						if plsr.Crypto.Exchange:Remove(coin, char:GetData("CryptoWallet"), math.abs(amount), true) then
							plsr.Phone.Notification:Add(
								char:GetData("Source"),
								"Crypto Transfer",
								string.format("You Sent %s $%s", amount, coin),
								os.time(),
								config.Notifications.cryptoMs,
								"crypto",
								{}
							)

							if plsr.Crypto.Exchange:Add(coin, target, math.abs(amount), true) then
								if tChar then
									plsr.Phone.Notification:Add(
										tChar:GetData("Source"),
										"Crypto Transfer",
										string.format("You Received %s $%s", amount, coin),
										os.time(),
										config.Notifications.cryptoMs,
										"crypto",
										{}
									)
								end

								return true
							end
						end
					end
				end
			end
			return false
		end,
	},
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Crypto", _CRYPTO)
end)
