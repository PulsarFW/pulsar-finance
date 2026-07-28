local inBank = true

-- Maps a bank branch's _bankBranches key (config/shared.lua's Locations.branches) to a real
-- brand for SET_APP — the front-end's brand switch always supported
-- fleeca/maze/blaineco/ud, it just never received anything but "fleeca"
-- before. ATM stays hardcoded to fleeca (atms.lua's zones carry no
-- per-location brand data to key off).
function GetBranchBrand(branchKey)
	if not branchKey then return "fleeca" end
	if string.find(branchKey, "^mazebank_") then return "maze" end
	if string.find(branchKey, "^savings_") then return "blaineco" end
	if string.find(branchKey, "^lombank_") then return "ud" end
	return "fleeca"
end

function TableLength(tbl)
	local c = 0
	for k, v in pairs(tbl) do
		c += 1
	end
	return c
end

CreateThread(function()
		RunBankingStartup()

		plsr.PedInteraction:Add("paycheck", `ig_bankman`, vector3(253.193, 216.434, 105.282), 339.578, 25.0, {
			{
				icon = "hand-holding-dollar",
				text = "Get Paycheck",
				event = "Finance:Client:Paycheck",
				isEnabled = function()
					return TableLength(plsr.State.character.Salary or {}) > 0
				end,
			},
		}, "money-check-dollar")

		plsr.Targeting.Zones:AddBox(
			"paycheck-zone",
			"money-check-dollar",
			vector3(254.53, 216.58, 106.28),
			0.8,
			3.6,
			{
				name = "paycheck",
				heading = 340,
				--debugPoly=true,
				minZ = 105.28,
				maxZ = 108.28,
			},
			{
				{
					icon = "hand-holding-dollar",
					text = "Get Paycheck",
					event = "Finance:Client:Paycheck",
					isEnabled = function()
						return TableLength(plsr.State.character.Salary or {}) > 0
					end,
				},
			},
			3.0,
			true
		)

		plsr.PedInteraction:Add("paycheck-2", `ig_bankman`, vector3(17.568, -927.223, 28.903), 111.958, 25.0, {
			{
				icon = "hand-holding-dollar",
				text = "Get Paycheck",
				event = "Finance:Client:Paycheck",
				isEnabled = function()
					return TableLength(plsr.State.character.Salary or {}) > 0
				end,
			},
		}, "money-check-dollar")

		plsr.Targeting.Zones:AddBox(
			"paycheck-zone-2",
			"money-check-dollar",
			vector3(16.72, -927.74, 29.9),
			2.0,
			1.0,
			{
				name = "paycheck",
				heading = 15,
				--debugPoly=true,
				minZ = 29.7,
				maxZ = 31.3,
			},
			{
				{
					icon = "hand-holding-dollar",
					text = "Get Paycheck",
					event = "Finance:Client:Paycheck",
					isEnabled = function()
						return TableLength(plsr.State.character.Salary or {}) > 0
					end,
				},
			},
			3.0,
			true
		)

		plsr.PedInteraction:Add("paycheck-3", `ig_bankman`, vector3(-108.997, 6471.589, 30.634), 224.685, 25.0, {
			{
				icon = "hand-holding-dollar",
				text = "Get Paycheck",
				event = "Finance:Client:Paycheck",
				isEnabled = function()
					return TableLength(plsr.State.character.Salary or {}) > 0
				end,
			},
		}, "money-check-dollar")

		plsr.Targeting.Zones:AddBox(
			"paycheck-zone-3",
			"money-check-dollar",
			vector3(-109.04, 6471.68, 31.63),
			1.6,
			1.2,
			{
				name = "paycheck",
				heading = 315,
				--debugPoly=true,
				minZ = 28.83,
				maxZ = 32.83,
			},
			{
				{
					icon = "hand-holding-dollar",
					text = "Get Paycheck",
					event = "Finance:Client:Paycheck",
					isEnabled = function()
						return TableLength(plsr.State.character.Salary or {}) > 0
					end,
				},
			},
			3.0,
			true
		)

		plsr.Interaction:RegisterMenu("cash", "Show Cash", "dollar-sign", function()
			TriggerServerEvent("Wallet:ShowCash")
			plsr.Interaction:Hide()
		end)
end)

RegisterNetEvent("UI:Client:Reset", function()
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "APP_HIDE",
		data = {},
	})
end)

AddEventHandler("Finance:Client:Paycheck", function(entity, data)
	plsr.Callbacks:ServerCallback("Finance:Paycheck", {}, function(s)
		if s.total > 0 then
			plsr.Notification:Success(string.format("You Received $%s For %s Total Minutes Worked", s.total, s.minutes))
		else
			plsr.Notification:Error("You Need To Work To Earn A Paycheck")
		end
	end)
end)

RegisterNUICallback("Close", function(data, cb)
	SetNuiFocus(false, false)
	SendNUIMessage({
		type = "APP_HIDE",
	})

	if not inBank then
		plsr.Progress:Progress({
			name = "atm_removing",
			duration = 1500,
			label = "Removing Card",
			useWhileDead = false,
			canCancel = false,
			ignoreModifier = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = "amb@prop_human_atm@male@idle_a",
				anim = "idle_b",
				flags = 49,
			},
			disarm = true,
		}, function(cancelled) end)
	end

	inBank = false
end)

RegisterNetEvent("Finance:Client:OpenUI", function(branchKey)
	inBank = true
	SetNuiFocus(true, true)
	SendNUIMessage({
		type = "SET_APP",
		data = {
			brand = GetBranchBrand(branchKey),
			app = "BANK",
		},
	})
end)

AddEventHandler("Characters:Client:Updated", function(key)
	if key == "Cash" then
		SendNUIMessage({
			type = "SET_DATA",
			data = {
				type = "character",
				data = {
					ID = plsr.State.character.ID,
					SID = plsr.State.character.SID,
					First = plsr.State.character.First,
					Last = plsr.State.character.Last,
					Cash = plsr.State.character.Cash,
				},
			},
		})
	end
end)

AddEventHandler("Characters:Client:Spawn", function()
	SendNUIMessage({
		type = "SET_DATA",
		data = {
			type = "character",
			data = {
				ID = plsr.State.character.ID,
				SID = plsr.State.character.SID,
				First = plsr.State.character.First,
				Last = plsr.State.character.Last,
				Cash = plsr.State.character.Cash,
			},
		},
	})
end)

RegisterNetEvent("Finance:Client:HandOffCash", function()
	loadAnimDict("mp_safehouselost@")
	TaskPlayAnim(PlayerPedId(), "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 48, 0, 0, 0, 0)
end)
