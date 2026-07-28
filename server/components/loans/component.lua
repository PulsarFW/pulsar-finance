local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _loansTablesReady = false
function EnsureLoansTables(callback)
	if _loansTablesReady then
		if callback then
			callback()
		end
		return
	end
	plsr.Database:Query(
		"CREATE TABLE IF NOT EXISTS `loans` (`id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, `sid` BIGINT UNSIGNED NOT NULL, `type` VARCHAR(20) NOT NULL, `asset_identifier` VARCHAR(191) NOT NULL, `defaulted` TINYINT(1) NOT NULL DEFAULT 0, `interest_rate` DOUBLE NOT NULL, `total` DOUBLE NOT NULL, `remaining` DOUBLE NOT NULL, `paid` DOUBLE NOT NULL DEFAULT 0, `down_payment` DOUBLE NOT NULL DEFAULT 0, `total_payments` INT NOT NULL, `paid_payments` INT NOT NULL DEFAULT 0, `missable_payments` INT NOT NULL, `missed_payments` INT NOT NULL DEFAULT 0, `total_missed_payments` INT NOT NULL DEFAULT 0, `next_payment` BIGINT NOT NULL DEFAULT 0, `last_payment` BIGINT NOT NULL DEFAULT 0, `last_missed_payment` BIGINT NULL, `creation` BIGINT NOT NULL, INDEX `idx_sid` (`sid`), INDEX `idx_type_asset` (`type`, `asset_identifier`), INDEX `idx_remaining` (`remaining`), INDEX `idx_defaulted` (`defaulted`), INDEX `idx_next_payment` (`next_payment`))",
		nil,
		function()
			plsr.Database:Query(
				"CREATE TABLE IF NOT EXISTS `loans_credit_scores` (`sid` BIGINT UNSIGNED PRIMARY KEY, `score` INT NOT NULL)",
				nil,
				function()
					_loansTablesReady = true
					if callback then
						callback()
					end
				end
			)
		end
	)
end

function RowToLoan(row)
	if row == nil then
		return nil
	end
	return {
		_id = row.id,
		SID = row.sid,
		Type = row.type,
		AssetIdentifier = row.asset_identifier,
		Defaulted = row.defaulted == 1,
		InterestRate = row.interest_rate,
		Total = row.total,
		Remaining = row.remaining,
		Paid = row.paid,
		DownPayment = row.down_payment,
		TotalPayments = row.total_payments,
		PaidPayments = row.paid_payments,
		MissablePayments = row.missable_payments,
		MissedPayments = row.missed_payments,
		TotalMissedPayments = row.total_missed_payments,
		NextPayment = row.next_payment,
		LastPayment = row.last_payment,
		LastMissedPayment = row.last_missed_payment,
		Creation = row.creation,
	}
end

_LOANS = {
	GetAllowedLoanAmount = function(self, stateId, type)
		if not type then
			type = "vehicle"
		end
		if config.CreditScore.allowedLoanMultipliers[type] then
			local creditScore = GetCharacterCreditScore(stateId)

			local creditMult = 0
			for k, v in ipairs(config.CreditScore.allowedLoanMultipliers[type]) do
				if creditScore >= v.value then
					creditMult = v.multiplier
				else
					break
				end
			end

			return {
				creditScore = creditScore,
				maxBorrowable = creditScore * creditMult,
				limit = creditScore > config.Loans.maxActiveLoans.highCreditScoreThreshold and config.Loans.maxActiveLoans.highCreditScore or config.Loans.maxActiveLoans.default,
			}
		end
	end,
	GetDefaultInterestRate = function(self)
		return config.Loans.defaultInterestRate
	end,
	GetPlayerLoans = function(self, stateId, type)
		local p = promise.new()
		EnsureLoansTables(function()
			plsr.Database:Query(
				"SELECT * FROM `loans` WHERE `sid` = ? AND `type` = ? AND (`remaining` > 0 OR (`remaining` = 0 AND `last_payment` >= ?))",
				{ stateId, type, os.time() - (60 * 60 * 24 * 1) },
				function(success, results)
					if not success then
						p:resolve(false)
						return
					end
					local loans = {}
					for _, row in ipairs(results) do
						table.insert(loans, RowToLoan(row))
					end
					p:resolve(loans)
				end
			)
		end)
		return Citizen.Await(p)
	end,
	CreateVehicleLoan = function(self, targetSource, VIN, totalCost, downPayment, totalWeeks)
		local char = plsr.Fetch:CharacterSource(targetSource)
		if char then
			local p = promise.new()
			local remainingCost = totalCost - downPayment
			local timeStamp = os.time()

			EnsureLoansTables(function()
				plsr.Database:Insert(
					"INSERT INTO `loans` (`sid`, `type`, `asset_identifier`, `defaulted`, `interest_rate`, `total`, `remaining`, `paid`, `down_payment`, `total_payments`, `paid_payments`, `missable_payments`, `missed_payments`, `total_missed_payments`, `next_payment`, `last_payment`, `creation`) VALUES (?, 'vehicle', ?, 0, ?, ?, ?, ?, ?, ?, 0, ?, 0, 0, ?, 0, ?)",
					{
						char:GetData("SID"),
						VIN,
						config.Loans.defaultInterestRate,
						totalCost,
						remainingCost,
						downPayment,
						downPayment,
						totalWeeks,
						config.Loans.missedPayments.limit,
						timeStamp + config.Loans.paymentInterval,
						timeStamp,
					},
					function(success, newId)
						p:resolve(success and newId ~= nil)
					end
				)
			end)

			local res = Citizen.Await(p)
			return res
		end
		return false
	end,
	CreatePropertyLoan = function(self, targetSource, propertyId, totalCost, downPayment, totalWeeks)
		local char = plsr.Fetch:CharacterSource(targetSource)
		if char then
			local p = promise.new()
			local remainingCost = totalCost - downPayment
			local timeStamp = os.time()

			EnsureLoansTables(function()
				plsr.Database:Insert(
					"INSERT INTO `loans` (`sid`, `type`, `asset_identifier`, `defaulted`, `interest_rate`, `total`, `remaining`, `paid`, `down_payment`, `total_payments`, `paid_payments`, `missable_payments`, `missed_payments`, `total_missed_payments`, `next_payment`, `last_payment`, `creation`) VALUES (?, 'property', ?, 0, ?, ?, ?, ?, ?, ?, 0, ?, 0, 0, ?, 0, ?)",
					{
						char:GetData("SID"),
						propertyId,
						config.Loans.defaultInterestRate,
						totalCost,
						remainingCost,
						downPayment,
						downPayment,
						totalWeeks,
						config.Loans.missedPayments.limit,
						timeStamp + config.Loans.paymentInterval,
						timeStamp,
					},
					function(success, newId)
						p:resolve(success and newId ~= nil)
					end
				)
			end)

			local res = Citizen.Await(p)
			return res
		end
		return false
	end,
	MakePayment = function(self, source, loanId, inAdvanced, advancedPaymentCount)
		local char = plsr.Fetch:CharacterSource(source)
		if char then
			local SID = char:GetData("SID")
			local Account = char:GetData("BankAccount")
			local loan = GetLoanByID(loanId, SID)
			if loan then
				local timeStamp = os.time()

				local remainingPayments = loan.TotalPayments - loan.PaidPayments

				local totalCreditGained = config.CreditScore.addition.loanPaymentMin
				if loan.Total >= config.Loans.largeLoanCreditBonus.perAmount then
					totalCreditGained += (math.floor(loan.Total / config.Loans.largeLoanCreditBonus.perAmount) * config.Loans.largeLoanCreditBonus.bonus)

					if totalCreditGained > config.CreditScore.addition.loanPaymentMax then
						totalCreditGained = config.CreditScore.addition.loanPaymentMax
					end
				end

				if remainingPayments > 0 and loan.Remaining > 0 then
					local interestMult = ((100 + loan.InterestRate) / 100)
					local creditScoreIncrease = 0
					local actuallyAdvancedPayments = 0
					local payments = 1
					if loan.MissedPayments > 0 then
						payments = loan.MissedPayments

						if payments > remainingPayments then
							payments = remainingPayments
						end

						creditScoreIncrease += math.floor(((totalCreditGained / loan.TotalPayments) * payments) / 2)
					else
						local timeUntilDue = loan.NextPayment - timeStamp
						local doneMinLoanLength = (timeStamp - loan.Creation) >= (60 * 60 * 24 * config.Loans.minAgeForEarlyPaymentDays)

						if timeUntilDue >= (config.Loans.paymentInterval * 4) and not doneMinLoanLength then -- Can only pay 2 weeks in advanced or wait until loan is 1 week old
							return {
								success = false,
								message = "Can't Pay That Far in Advanced - Hold Loan For At Least 5 Days",
							}
						end

						local loanPaymentCreditIncrease = math.floor(totalCreditGained / loan.TotalPayments)
						creditScoreIncrease += loanPaymentCreditIncrease

						local earlyTime = loan.NextPayment - (config.Loans.paymentInterval * 0.5)
						if timeStamp <= earlyTime then -- Well Done You Are Early
							creditScoreIncrease += config.Loans.earlyPaymentCreditBonus
						end
					end

					-- TODO: (maybe) Interest Going to the Government Account?

					local dueAmount = math.ceil(((loan.Remaining / remainingPayments) * payments) * interestMult)
					local chargeSuccess = plsr.Banking.Balance:Charge(Account, dueAmount, {
						type = "loan",
						title = "Loan Payment",
						description = string.format(
							"Loan Payment for %s %s",
							GetLoanTypeName(loan.Type),
							loan.AssetIdentifier
						),
						data = {
							loan = loan._id,
						},
					})

					if chargeSuccess then
						local loanPaidOff = false
						local nowRemainingPayments = remainingPayments - payments
						if nowRemainingPayments <= 0 then
							loanPaidOff = true
						end

						if loan.Defaulted then -- Unseize Assets
							if loan.Type == "vehicle" then
								plsr.Vehicles.Owned:Seize(loan.AssetIdentifier, false)
							elseif loan.Type == "property" then
								plsr.Properties.Commerce:Foreclose(loan.AssetIdentifier, false)
							end
						end

						local updated
						if loanPaidOff then
							if loan.TotalMissedPayments <= 0 then
								creditScoreIncrease += config.CreditScore.addition.completingLoanNoMissed
							else
								creditScoreIncrease += config.CreditScore.addition.completingLoan
							end

							updated = UpdateLoanById(
								loan._id,
								"UPDATE `loans` SET `last_payment` = ?, `next_payment` = 0, `remaining` = 0, `defaulted` = 0, `paid` = `paid` + ?, `paid_payments` = `paid_payments` + ? WHERE `id` = ?",
								{ timeStamp, dueAmount, payments }
							)
						else
							local extraSet = ""
							if loan.MissedPayments > 0 then
								extraSet = ", `missed_payments` = 0, `missable_payments` = "
									.. tostring(math.max(1, loan.MissablePayments - loan.MissedPayments))
							end

							updated = UpdateLoanById(
								loan._id,
								"UPDATE `loans` SET `last_payment` = ?, `next_payment` = ?, `defaulted` = 0, `paid` = `paid` + ?, `paid_payments` = `paid_payments` + ?, `remaining` = `remaining` - ?"
									.. extraSet
									.. " WHERE `id` = ?",
								{ timeStamp, loan.NextPayment + config.Loans.paymentInterval, dueAmount, payments, dueAmount }
							)
						end

						if creditScoreIncrease > 0 then
							IncreaseCharacterCreditScore(SID, creditScoreIncrease)
						end

						if updated then
							return {
								success = true,
								paidOff = loanPaidOff,
								paymentAmount = dueAmount,
								creditIncrease = creditScoreIncrease,
							}
						end
					else
						return {
							success = false,
							message = "Insufficient Funds in Checking Account",
						}
					end
				end
			end
		end
		return {
			success = false,
		}
	end,
	HasRemainingPayments = function(self, assetType, assetId, checkAge)
		-- checkAge (check if older than certain age (days))
		local p = promise.new()
		EnsureLoansTables(function()
			plsr.Database:Single("SELECT * FROM `loans` WHERE `type` = ? AND `asset_identifier` = ?", { assetType, assetId }, function(success, row)
				if not success or row == nil then
					p:resolve(false)
					return
				end

				local l = RowToLoan(row)

				if checkAge and l.Creation >= (os.time() - (60 * 60 * 24 * checkAge)) then
					p:resolve(true)
					return
				end

				if l and l.Remaining and l.Remaining > 0 then
					p:resolve(true)
				else
					p:resolve(false)
				end
			end)
		end)

		return Citizen.Await(p)
	end,
	Credit = {
		Get = function(self, stateId)
			return GetCharacterCreditScore(stateId)
		end,
		Set = function(self, stateId, newVal)
			return SetCharacterCreditScore(stateId, newVal)
		end,
		Increase = function(self, stateId, increase)
			return IncreaseCharacterCreditScore(stateId, increase)
		end,
		Decrease = function(self, stateId, decrease)
			return DecreaseCharacterCreditScore(stateId, decrease)
		end,
	},
	HasBeenDefaulted = function(self, assetType, assetId)
		local p = promise.new()

		EnsureLoansTables(function()
			plsr.Database:Single(
				"SELECT * FROM `loans` WHERE `type` = ? AND `asset_identifier` = ? AND `defaulted` = 1",
				{ assetType, assetId },
				function(success, row)
					if success and row ~= nil then
						p:resolve(RowToLoan(row))
					else
						p:resolve(false)
					end
				end
			)
		end)

		return Citizen.Await(p)
	end,
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Loans", _LOANS)
end)

function GetLoanByID(loanId, stateId)
	local p = promise.new()
	EnsureLoansTables(function()
		plsr.Database:Single("SELECT * FROM `loans` WHERE `id` = ? AND `sid` = ?", { loanId, stateId }, function(success, row)
			if success and row ~= nil then
				p:resolve(RowToLoan(row))
			else
				p:resolve(false)
			end
		end)
	end)

	local res = Citizen.Await(p)
	return res
end

-- sql must end with "WHERE `id` = ?"; params excludes that final loanId (appended here).
function UpdateLoanById(loanId, sql, params)
	local p = promise.new()
	local fullParams = { table.unpack(params) }
	table.insert(fullParams, loanId)

	plsr.Database:Update(sql, fullParams, function(success, updated)
		if success and updated > 0 then
			p:resolve(true)
		else
			p:resolve(false)
		end
	end)

	local res = Citizen.Await(p)
	return res
end
