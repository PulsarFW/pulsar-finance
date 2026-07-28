local config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

function AddBankingATMs()
	for k, v in ipairs(config.Locations.atmProps) do
		plsr.Targeting:AddObject(v, "credit-card", {
			{
				text = "Use ATM",
				icon = "dollar-sign",
				event = "Banking:Client:StartOpenATM",
				data = {},
				minDist = 3.0,
			},
		}, 3.0)
	end

	for k, v in ipairs(config.Locations.atmZones) do
		plsr.Targeting.Zones:AddBox("atm-" .. k, "credit-card", v.center, v.length, v.width, v.options, {
			{
				text = "Use ATM",
				icon = "dollar-sign",
				event = "Banking:Client:StartOpenATM",
				data = {},
				minDist = 3.0,
			},
		}, 3.0, true)
	end
end

AddEventHandler("Banking:Client:StartOpenATM", function(entityData)
	plsr.Progress:Progress({
		name = "atm_inserting",
		duration = 3000,
		label = "Inserting Card",
		useWhileDead = false,
		canCancel = true,
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
	}, function(cancelled)
		if not cancelled then
			SetNuiFocus(true, true)
			SendNUIMessage({
				type = "SET_APP",
				data = {
					brand = "fleeca",
					app = "ATM",
				},
			})
		end
	end)
end)
