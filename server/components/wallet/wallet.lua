local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

AddEventHandler("Finance:Server:Startup", function()
	plsr.Callbacks:RegisterServerCallback("Wallet:GetCash", function(source, data, cb)
		cb(plsr.Wallet:Get(source))
	end)

	plsr.Callbacks:RegisterServerCallback("Wallet:GiveCash", function(source, data, cb)
		local char = plsr.Fetch:CharacterSource(source)
		local targetChar = plsr.Fetch:SID(data.target)

		if char ~= nil and targetChar ~= nil then
			local playerCoords = GetEntityCoords(GetPlayerPed(source))
			local targetCoords = GetEntityCoords(GetPlayerPed(targetChar:GetData("Source")))

			if #(playerCoords - targetCoords) <= config.Wallet.giveCashDistance then
				local amount = math.tointeger(data.amount)
				if amount and amount > 0 then
					if plsr.Wallet:Modify(source, -amount, true) then
						if plsr.Wallet:Modify(targetChar:GetData("Source"), amount, true) then
							TriggerClientEvent('Finance:Client:HandOffCash', source)
							plsr.Execute:Client(
								source,
								"Notification",
								"Success",
								"You Gave $" .. formatNumberToCurrency(amount) .. " in Cash"
							)
							plsr.Execute:Client(
								targetChar:GetData("Source"),
								"Notification",
								"Success",
								"You Just Received $" .. formatNumberToCurrency(amount) .. " in Cash"
							)
							return
						else
							return plsr.Chat.Send.System:Single(source, "Error")
						end
					else
						return plsr.Chat.Send.System:Single(source, "Not Enough Cash")
					end
				else
					return plsr.Chat.Send.System:Single(source, "Invalid Amount")
				end
			else
				return plsr.Chat.Send.System:Single(source, "Target Not Nearby")
			end
		else
			cb(false)
		end
	end)

	plsr.Chat:RegisterCommand("cash", function(source, args, rawCommand)
		ShowCash(source)
	end, {
		help = "Show Current Cash",
	})

	plsr.Chat:RegisterAdminCommand("addcash", function(source, args, rawCommand)
		local addingAmount = tonumber(args[1])
		if addingAmount and addingAmount > 0 then
			plsr.Wallet:Modify(source, addingAmount)
		end
	end, {
		help = "Give Cash To Yourself",
		params = {
			{
				name = "Amount",
				help = "Amount of cash to give",
			},
		},
	}, 1)

	plsr.Chat:RegisterCommand("givecash", function(source, args, rawCommand)
		local target = tonumber(args[1])
		if target and target > 0 then
			local char = plsr.Fetch:CharacterSource(source)
			local targetChar = plsr.Fetch:SID(target)

			if char and targetChar and targetChar:GetData("Source") ~= char:GetData("Source") then
				local playerCoords = GetEntityCoords(GetPlayerPed(source))
				local targetCoords = GetEntityCoords(GetPlayerPed(targetChar:GetData("Source")))

				if #(playerCoords - targetCoords) <= config.Wallet.giveCashDistance then
					local amount = math.tointeger(args[2])
					if amount and amount > 0 then
						if plsr.Wallet:Modify(source, -amount, true) then
							if plsr.Wallet:Modify(targetChar:GetData("Source"), amount, true) then
								TriggerClientEvent('Finance:Client:HandOffCash', source)
								plsr.Execute:Client(
									source,
									"Notification",
									"Success",
									"You Gave $" .. formatNumberToCurrency(amount) .. " in Cash"
								)
								plsr.Execute:Client(
									targetChar:GetData("Source"),
									"Notification",
									"Success",
									"You Just Received $" .. formatNumberToCurrency(amount) .. " in Cash"
								)
								return
							else
								return plsr.Chat.Send.System:Single(source, "Error")
							end
						else
							return plsr.Chat.Send.System:Single(source, "Not Enough Cash")
						end
					else
						return plsr.Chat.Send.System:Single(source, "Invalid Amount")
					end
				else
					return plsr.Chat.Send.System:Single(source, "Target Not Nearby")
				end
			end
		end
		plsr.Chat.Send.System:Single(source, "Invalid State ID")
	end, {
		help = "Give Your Cash to a Person",
		params = {
			{
				name = "State ID",
				help = "The person you want to give the cash to has to be nearby",
			},
			{
				name = "Amount",
				help = "The amount of money to give",
			},
		},
	}, 2)
end)

function ShowCash(source)
	plsr.Execute:Client(
		source,
		"Notification",
		"Success",
		"You have $" .. formatNumberToCurrency(plsr.Wallet:Get(source)),
		config.Notifications.walletShowCashMs,
		"money-bill-wave"
	)
end

RegisterServerEvent("Wallet:ShowCash", function()
	local source = source
	ShowCash(source)
end)
