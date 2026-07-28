local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

function GetCharacterCreditScore(stateId)
    local p = promise.new()
    EnsureLoansTables(function()
        plsr.Database:Scalar("SELECT `score` FROM `loans_credit_scores` WHERE `sid` = ?", { stateId }, function(success, score)
            if success and score ~= nil then
                p:resolve(score)
            else
                p:resolve(config.CreditScore.default)
            end
        end)
    end)

    local res = Citizen.Await(p)
    return res
end

function SetCharacterCreditScore(stateId, score)
    local p = promise.new()

    if score > config.CreditScore.max then
        score = config.CreditScore.max
    end

    if score < config.CreditScore.min then
        score = config.CreditScore.min
    end

    EnsureLoansTables(function()
        plsr.Database:Update(
            "INSERT INTO `loans_credit_scores` (`sid`, `score`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `score` = VALUES(`score`)",
            { stateId, score },
            function(success)
                if success then
                    p:resolve(score)
                else
                    p:resolve(false)
                end
            end
        )
    end)

    local res = Citizen.Await(p)
    return res
end

function IncreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.min(config.CreditScore.max, creditScore + amount))
end

function DecreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.max(config.CreditScore.min, creditScore - amount))
end