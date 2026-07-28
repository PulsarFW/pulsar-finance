local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _ranStartup = false

function RunLoanStartup()
    if _ranStartup then return end
    _ranStartup = true

    EnsureLoansTables(function()
        plsr.Database:Scalar("SELECT COUNT(*) FROM `loans` WHERE `remaining` > 0", nil, function(success, count)
            if success then
                plsr.Logger:Trace('Loans', 'Loaded ^2' .. count .. '^7 Active Loans')
            end
        end)
    end)
end

AddEventHandler('Finance:Server:Startup', function()
    RunLoanStartup()
    RegisterLoanCallbacks()

    CreateLoanTasks()
end)

function CreateLoanTasks()
    plsr.Tasks:Register('loan_payment', 60, function()
    --RegisterCommand('testloans', function()
        local TASK_RUN_TIMESTAMP = os.time()

        EnsureLoansTables(function()
            plsr.Database:Update(
                "UPDATE `loans` SET `interest_rate` = `interest_rate` + ?, `last_missed_payment` = ?, `missed_payments` = `missed_payments` + 1, `total_missed_payments` = `total_missed_payments` + 1, `next_payment` = `next_payment` + ?, `remaining` = `remaining` + (`total` * ?) WHERE `next_payment` > 0 AND `next_payment` <= ? AND `defaulted` = 0 AND `remaining` >= 0",
                {
                    config.Loans.missedPayments.interestIncrease,
                    TASK_RUN_TIMESTAMP,
                    config.Loans.paymentInterval,
                    (config.Loans.missedPayments.charge / 100),
                    TASK_RUN_TIMESTAMP,
                },
                function(success)
                    if not success then
                        return
                    end

                    -- Loans that are now over the missable-payments limit get defaulted, notified, seized
                    plsr.Database:Query(
                        "SELECT * FROM `loans` WHERE `missed_payments` >= `missable_payments` AND `defaulted` = 0",
                        nil,
                        function(qSuccess, results)
                            if not qSuccess or #results == 0 then
                                return
                            end

                            local updatingAssets = {}
                            for k, row in ipairs(results) do
                                table.insert(updatingAssets, row.asset_identifier)
                            end

                            local placeholders = {}
                            for i = 1, #updatingAssets do
                                table.insert(placeholders, "?")
                            end

                            plsr.Database:Update(
                                "UPDATE `loans` SET `defaulted` = 1 WHERE `asset_identifier` IN (" .. table.concat(placeholders, ", ") .. ")",
                                updatingAssets,
                                function(updateSuccess)
                                    if updateSuccess then
                                        plsr.Logger:Info('Loans', '^2' .. #results .. '^7 Loans Have Just Been Defaulted')
                                        for k, row in ipairs(results) do
                                            local v = RowToLoan(row)
                                            if v.SID then
                                                DecreaseCharacterCreditScore(v.SID, config.CreditScore.removal.defaultedLoan)
                                                local onlineChar = plsr.Fetch:SID(v.SID)
                                                if onlineChar then
                                                    SendDefaultedLoanNotification(onlineChar:GetData('Source'), v)
                                                end
                                            end

                                            if v.AssetIdentifier then
                                                if v.Type == 'vehicle' then
                                                    plsr.Vehicles.Owned:Seize(v.AssetIdentifier, true)
                                                elseif v.Type == 'property' then
                                                    plsr.Properties.Commerce:Foreclose(v.AssetIdentifier, true)
                                                end
                                            end
                                        end
                                    end
                                end
                            )
                        end
                    )

                    -- Notify if someone just missed a payment.
                    plsr.Database:Query(
                        "SELECT * FROM `loans` WHERE `missed_payments` < `missable_payments` AND `defaulted` = 0 AND `last_missed_payment` = ?",
                        { TASK_RUN_TIMESTAMP },
                        function(qSuccess, results)
                            if qSuccess and #results > 0 then
                                plsr.Logger:Info('Loans', '^2' .. #results .. '^7 Loan Payments Were Just Missed')
                                for k, row in ipairs(results) do
                                    local v = RowToLoan(row)
                                    if v.SID then
                                        DecreaseCharacterCreditScore(v.SID, config.CreditScore.removal.missedLoanPayment)

                                        local onlineChar = plsr.Fetch:SID(v.SID)
                                        if onlineChar then
                                            SendMissedLoanNotification(onlineChar:GetData('Source'), v)
                                        end
                                    end
                                end
                            end
                        end
                    )
                end
            )
        end)
    end)

    plsr.Tasks:Register('loan_reminder', 120, function()
        local TASK_RUN_TIMESTAMP = os.time()
        -- Get All Loans That are Due Soon
        EnsureLoansTables(function()
            plsr.Database:Query(
                "SELECT * FROM `loans` WHERE `remaining` > 0 AND `defaulted` = 0 AND ((`next_payment` > 0 AND `next_payment` <= ?) OR `missed_payments` > 0)",
                { TASK_RUN_TIMESTAMP + (60 * 60 * 6) },
                function(success, results)
                    if success and #results > 0 then
                        for k, row in ipairs(results) do
                            local v = RowToLoan(row)
                            if v.SID then
                                local onlineChar = plsr.Fetch:SID(v.SID)
                                if onlineChar then
                                    plsr.Phone.Notification:Add(onlineChar:GetData("Source"), "Loan Payment Due", "You have a loan payment that is due very soon.", os.time(), 7500, "loans", {})
                                end

                                Wait(100)
                            end
                        end
                    end
                end
            )
        end)
    end)
end

function SendMissedLoanNotification(source, loanData)
    plsr.Phone.Notification:Add(source, "Loan Payment Missed", "You just missed a loan payment on one of your loans.", os.time(), 7500, "loans", {})
end

function SendDefaultedLoanNotification(source, loanData)
    plsr.Phone.Notification:Add(source, "Loan Defaulted", "One of your loans just got defaulted and the assets are going to be seized.", os.time(), 7500, "loans", {})
end

local typeNames = {
    vehicle = 'Vehicle Loan',
    property = 'Property Loan',
}

function GetLoanTypeName(type)
    return typeNames[type]
end