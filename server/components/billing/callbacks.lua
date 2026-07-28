local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

AddEventHandler('Finance:Server:Startup', function()
    plsr.Callbacks:RegisterServerCallback('Billing:DismissBill', function(source, data, cb)
        if data and data.bill then
            local success = plsr.Billing:Dismiss(source, data.bill)
            cb(success)
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Billing:AcceptBill', function(source, data, cb)
        if data and data.bill then
            local success = plsr.Billing:Accept(source, data.bill, data.account)
            cb(success)
            if data.notify then
                if success then
                    plsr.Phone.Notification:Add(source, "Bill Payment Successful", false, os.time(), config.Notifications.billingPaymentMs, "bank", {})
                else
                    plsr.Phone.Notification:Add(source, "Bill Payment Failed", false, os.time(), config.Notifications.billingPaymentMs, "bank", {})
                end
            end
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Billing:CreateBill', function(source, data, cb)
        if data and data.fromAccount and data.target and data.description and data.amount then
            local creationSuccess = plsr.Billing:PlayerCreateOrganizationBill(source, data.target, data.fromAccount, data.amount, data.description)
            cb(creationSuccess)
        end
    end)
end)