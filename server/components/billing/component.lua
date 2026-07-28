local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local pendingBillId = 0
PENDING_BILLS = {}
PENDING_BILLS_CB = {}

function GetBillingId()
    pendingBillId = pendingBillId + 1
    return pendingBillId
end

_BILLING = {
    Create = function(self, source, name, amount, description, cb)
        local char = plsr.Fetch:CharacterSource(source)
        if char then
            local stateId = char:GetData('SID')
            local newBillingId = GetBillingId()
            local billData = {
                Type = false,
                Id = newBillingId,
                Name = name,
                Account = false,
                Amount = amount,
                Description = description,
                Biller = false,
                Timestamp = os.time(),
            }
            
            if not PENDING_BILLS[stateId] then PENDING_BILLS[stateId] = {} end
            table.insert(PENDING_BILLS[stateId], billData)
            SendNewBillNotificationToPhone(source, billData)

            PENDING_BILLS_CB[newBillingId] = cb
            return true
        end
        return false
    end,
    PlayerCreateOrganizationBill = function(self, billingSource, stateId, account, amount, description)
        local amount = math.tointeger(amount)
        local targetChar = plsr.Fetch:SID(tonumber(stateId))
        local billingChar = plsr.Fetch:CharacterSource(billingSource)
        if account and amount and amount > 0 and (billingChar and targetChar) and (targetChar:GetData('SID') ~= billingChar:GetData('SID')) then
            local billerStateId = billingChar:GetData('SID')
            local account = plsr.Banking.Accounts:Get(account)
            if account and account.Type == 'organization' and HasBankAccountPermission(billingSource, account, 'BILL', billerStateId) then
                local targetStateId = targetChar:GetData('SID')
                local newBillingId = GetBillingId()
                local billData = {
                    Type = true,
                    Id = newBillingId,
                    Name = account.Name or account.Account,
                    Account = account.Account,
                    Amount = amount,
                    Description = description,
                    Biller = billerStateId,
                    Timestamp = os.time(),
                }

                if not PENDING_BILLS[targetStateId] then PENDING_BILLS[targetStateId] = {} end
                table.insert(PENDING_BILLS[targetStateId], billData)
                SendNewBillNotificationToPhone(targetChar:GetData('Source'), billData)

                PENDING_BILLS_CB[newBillingId] = function(wasPayed, withAccount)
                    if wasPayed then
                        local success = plsr.Banking.Balance:Deposit(billData.Account, billData.Amount, {
                            type = 'bill',
                            transactionAccount = withAccount,
                            title = 'Bill Payment',
                            description = string.format('Bill Payment From State ID: %s With Account: %s. Bill Description: %s', targetStateId, withAccount, billData.Description),
                            data = {
                                biller = billerStateId,
                                character = targetStateId,
                            }
                        })

                        if success then
                            plsr.Phone.Notification:Add(billingSource, "Bill Payment Received", string.format("Payment for a bill you sent to State ID: %s was just received.", targetStateId), os.time(), config.Notifications.billingReceivedMs, "bank", {})
                        end
                    end
                end
                return true
            end
        end
        return false
    end,
    Dismiss = function(self, source, billId)
        local char = plsr.Fetch:CharacterSource(source)
        if char and billId then
            local stateId = char:GetData('SID')
            local characterBills = PENDING_BILLS[stateId]
            for k, v in ipairs(characterBills) do
                if v.Id == billId then
                    if PENDING_BILLS_CB[billId] then
                        PENDING_BILLS_CB[billId](false)
                        PENDING_BILLS_CB[billId] = nil
                    end
                    PENDING_BILLS[stateId][k] = nil

                    return true
                end
            end
        end
        return false
    end,
    Accept = function(self, source, billId, withAccount)
        local char = plsr.Fetch:CharacterSource(source)
        if char and billId then
            local stateId = char:GetData('SID')
            local characterBills = PENDING_BILLS[stateId]
            for k, v in ipairs(characterBills) do
                if v.Id == billId then
                    local account = false
                    if withAccount then
                        account = plsr.Banking.Accounts:Get(withAccount)
                    else
                        account = plsr.Banking.Accounts:GetPersonal(stateId)
                    end
                    if PENDING_BILLS_CB[billId] and account and (account.Balance >= v.Amount) and HasBankAccountPermission(source, account, 'WITHDRAW', stateId) then
                        local success = plsr.Banking.Balance:Withdraw(account.Account, v.Amount, {
                            type = 'bill',
                            transactionAccount = v.Account,
                            title = 'Payment for a Bill',
                            description = string.format('Payment for a Bill From %s. Bill Description: %s', v.Name, v.Description),
                            data = {
                                biller = v.Biller,
                                character = stateId,
                            }
                        })

                        if success then
                            if PENDING_BILLS_CB[billId] then
                                PENDING_BILLS_CB[billId](true, account.Account)
                                PENDING_BILLS_CB[billId] = nil
                            end
                            PENDING_BILLS[stateId][k] = nil
                            return true
                        end
                    end
                    break
                end
            end
        end
        return false
    end,
    Fine = function(self, finingSource, targetSource, amount)
        local amount = math.tointeger(amount)
        if amount and amount > 0 then
            local finingChar = plsr.Fetch:CharacterSource(finingSource)
            local targetChar = plsr.Fetch:CharacterSource(targetSource)

            if finingChar and targetChar and finingChar:GetData('SID') ~= targetChar:GetData('SID') then
                local targetCharSID = targetChar:GetData('SID')
                local finingCharSID = finingChar:GetData('SID')

                local targetCharAccount = plsr.Banking.Accounts:GetPersonal(targetCharSID)
                local finingCharAccount = plsr.Banking.Accounts:GetPersonal(finingCharSID)
                local policeJob = plsr.Jobs.Permissions:HasJob(finingSource, 'police')

                local policeAccount = plsr.Banking.Accounts:GetOrganization(string.format('police-%s', policeJob?.Workplace?.Id or ''))
                if not policeAccount then
                    policeAccount = plsr.Banking.Accounts:GetOrganization('police')
                end
                local stateAccount = plsr.Banking.Accounts:GetOrganization('government')

                if targetCharAccount and finingCharAccount then
                    local finerCut = config.Billing.fineSplits.finer
                    local policeCut = config.Billing.fineSplits.police
                    local stateCut = 1.0 - finerCut - policeCut

                    local finerCutAmount = math.floor(amount * finerCut)
                    local policeCutAmount = math.floor(amount * policeCut)
                    local stateCutAmount = math.floor(amount * stateCut)

                    local success = plsr.Banking.Balance:Withdraw(targetCharAccount.Account, amount, {
                        type = 'fine',
                        title = 'Fine Payment',
                        description = 'Fine From the State of San Andreas',
                        data = {
                            finer = finingCharSID
                        }
                    })

                    if success then
                        plsr.Banking.Balance:Deposit(finingCharAccount.Account, finerCutAmount, {
                            type = 'fine_profit',
                            title = 'Fine Profit',
                            description = string.format('Your Earned %% of Fine Profit', targetCharSID),
                            data = {
                                fined = targetCharSID,
                            }
                        })

                        if policeAccount then
                            plsr.Banking.Balance:Deposit(policeAccount.Account, policeCutAmount, {
                                type = 'fine_profit',
                                title = 'Fine Profit',
                                description = string.format('Fine Profit (Fine to State ID: %s By State ID: %s)', targetCharSID, finingCharSID),
                                data = {
                                    finer = finingCharSID,
                                    fined = targetCharSID,
                                }
                            })
                        end

                        if stateAccount then
                            plsr.Banking.Balance:Deposit(stateAccount.Account, stateCutAmount, {
                                type = 'fine_profit',
                                title = 'Fine Profit',
                                description = string.format('Fine Profit (Fine to State ID: %s By State ID: %s)', targetCharSID, finingCharSID),
                                data = {
                                    finer = finingCharSID,
                                    fined = targetCharSID,
                                }
                            })
                        end

                        plsr.Phone.Notification:Add(targetSource, "Received Fine", string.format("You received a fine of $%d from the State of San Andreas", amount), os.time(), config.Notifications.billingMs, "bank", {})

                        plsr.Logger:Info("Billing", string.format("%s %s (%s) Fined $%s By %s %s (%s).", targetChar:GetData("First"), targetChar:GetData("Last"), targetChar:GetData("SID"), amount, finingChar:GetData("First"), finingChar:GetData("Last"), finingChar:GetData("SID")), {
                            console = true,
                            file = true,
                            database = true,
                            discord = {
                                embed = true,
                                type = 'info',
                                webhook = GetConvar('discord_log_webhook', ''),
                            }
                        })

                        return {
                            amount = amount,
                            cut = finerCutAmount,
                        }
                    end
                end
            end
        end
        return false
    end,
    Charge = function(self, source, amount, title, description)
        local amount = math.tointeger(amount)
        if amount and amount > 0 then
            local targetChar = plsr.Fetch:CharacterSource(source)
            if targetChar then
                local targetCharSID = targetChar:GetData('SID')
                local targetCharAccount = plsr.Banking.Accounts:GetPersonal(targetCharSID)

                if targetCharAccount then
                    local success = plsr.Banking.Balance:Withdraw(targetCharAccount.Account, amount, {
                        type = 'bill',
                        title = title,
                        description = description,
                        data = {}
                    })

                    if success then
                        plsr.Phone.Notification:Add(source, "New Bank Charge", string.format("Received Charge of $%d - %s", amount, title), os.time(), config.Notifications.billingMs, "bank", {})

                        return amount
                    end
                end
            end
        end
        return false
    end,
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Billing", _BILLING)
end)

function SendNewBillNotificationToPhone(source, billData)
    plsr.Phone.Notification:Add(source, "Received New Bill", string.format("$%d Bill From %s", billData.Amount, billData.Name), os.time(), config.Notifications.billingMs, "bank", {
        accept = "Phone:Nui:Bank:AcceptBill",
        cancel = "Phone:Nui:Bank:DenyBill",
    }, {
        bill = billData.Id
    })
end