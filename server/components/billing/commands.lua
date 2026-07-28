local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

AddEventHandler('Finance:Server:Startup', function()
    plsr.Chat:RegisterCommand('fine', function(src, args, raw)
        local player = plsr.Fetch:SID(tonumber(args[1]))
        if player ~= nil then
            local targetSource, fineAmount = table.unpack(args)
            local fine = tonumber(fineAmount)
            if fine and fine > 0 and fine <= config.Billing.maxFineAmount then
                local success = plsr.Billing:Fine(src, player:GetData("Source"), fine)
                if success then
                    plsr.Chat.Send.System:Single(src, string.format("You Successfully Fined State ID %s For $%s. You earned $%s.", args[1], success.amount, success.cut))
                else
                    plsr.Chat.Send.System:Single(src, "Fine Failed")
                end
            else
                plsr.Chat.Send.System:Single(src, "Fine Amount Too High!")
            end
        else
            plsr.Chat.Send.System:Single(src, "Invalid Target")
        end
    end, {
        help = '[Government] Fine Someone',
        params = {
            { name = 'State ID', help = 'The State ID of the person you want to fine.' },
            { name = 'Amount', help = 'The amount of money you are fining them.' },
        },
    }, 2, {
        { Id = 'police' },
    })

    plsr.Chat:RegisterAdminCommand('testbilling', function(source, args, rawCommand)
        plsr.Execute:Client(source, 'Notification', 'Info', 'Bill Created')
        plsr.Billing:Create(source, 'Test Business', 1500, 'This is a test bill.', function(wasPayed)
            if wasPayed then
                plsr.Execute:Client(source, 'Notification', 'Success', 'Bill Accepted')
            else
                plsr.Execute:Client(source, 'Notification', 'Error', 'Bill Declined')
            end
        end)
    end, {
        help = 'Test Billing'
    }, 0)
end)