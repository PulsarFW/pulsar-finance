function GetCharactersLoans(stateId)
    local p = promise.new()

    EnsureLoansTables(function()
        plsr.Database:Query("SELECT * FROM `loans` WHERE `sid` = ?", { stateId }, function(success, results)
            if success and #results > 0 then
                local loans = {}
                for _, row in ipairs(results) do
                    table.insert(loans, RowToLoan(row))
                end
                p:resolve(loans)
            else
                p:resolve({})
            end
        end)
    end)

    local res = Citizen.Await(p)
    return res
end

function RegisterLoanCallbacks()
    plsr.Callbacks:RegisterServerCallback('Loans:GetLoans', function(source, data, cb)
        local char = plsr.Fetch:CharacterSource(source)
        if char then
            local SID = char:GetData('SID')
            local loans = GetCharactersLoans(SID)
            cb({
                loans = loans,
                creditScore = GetCharacterCreditScore(SID)
            })
        else
            cb(false)
        end
    end)

    plsr.Callbacks:RegisterServerCallback('Loans:Payment', function(source, data, cb)
        local char = plsr.Fetch:CharacterSource(source)
        if char and data and data.loan then
            local SID = char:GetData('SID')
            local res = plsr.Loans:MakePayment(source, data.loan, data.paymentAhead, data.weeks)
            if res and res.success then
                cb(res, {
                    loans = GetCharactersLoans(SID),
                    creditScore = GetCharacterCreditScore(SID),
                })
            else
                cb(res)
            end
        else
            cb(false)
        end
    end)
end