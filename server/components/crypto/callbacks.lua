-- New — thin RegisterServerCallback wrappers around the existing
-- plsr.Crypto.Exchange:Buy/Sell/Transfer component functions
-- (component.lua), registered under this resource's own Crypto:* prefix
-- (pulsar_phone's phone app wraps the same functions under Phone:Crypto:*,
-- kept separate — not cross-calling into pulsar_phone from here).
AddEventHandler("Finance:Server:Startup", function()
	plsr.Callbacks:RegisterServerCallback("Crypto:GetWallet", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			cb({
				WalletId = char:GetData("CryptoWallet"),
				Holdings = char:GetData("Crypto") or {},
			})
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Crypto:Buy", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data and data.coin and data.amount and data.amount > 0 then
			cb(plsr.Crypto.Exchange:Buy(data.coin, char:GetData("SID"), data.amount))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Crypto:Sell", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data and data.coin and data.amount and data.amount > 0 then
			cb(plsr.Crypto.Exchange:Sell(data.coin, char:GetData("SID"), data.amount))
		else
			cb(false)
		end
	end)

	plsr.Callbacks:RegisterServerCallback("Crypto:Transfer", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		if char and data and data.coin and data.target and data.amount and data.amount > 0 then
			cb(plsr.Crypto.Exchange:Transfer(data.coin, char:GetData("SID"), data.target, data.amount))
		else
			cb(false)
		end
	end)
end)
