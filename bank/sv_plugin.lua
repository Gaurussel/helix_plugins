local PLUGIN = PLUGIN
util.AddNetworkString("Bank.Open")
util.AddNetworkString("Bank.Transfer")
util.AddNetworkString("Bank.Withdraw")
util.AddNetworkString("Bank.Deposit")
util.AddNetworkString("Bank.Rob")

net.Receive("Bank.Deposit", function(_, ply)
    local character = ply:GetCharacter()

    if not character then
        return
    end

    local deposit = net.ReadUInt(24)

    if deposit > character:GetMoney() then
        return
    end

    character:SetMoney(character:GetMoney() - deposit)
    character:SetBankAmount(character:GetBankAmount() + deposit)

    ply:Notify("Successfull deposited " .. ix.currency.Get(deposit))
end)

net.Receive("Bank.Withdraw", function(_, ply)
    local character = ply:GetCharacter()

    if not character then
        return
    end

    local withdraw = net.ReadUInt(24)

    if withdraw > character:GetBankAmount() then
        return
    end

    character:SetMoney(character:GetMoney() + withdraw)
    character:SetBankAmount(character:GetBankAmount() - withdraw)

    ply:Notify("Successfull withdrawed " .. ix.currency.Get(withdraw))
end)

net.Receive("Bank.Transfer", function(_, ply)
    local character = ply:GetCharacter()

    if not character then
        return
    end

    local target = net.ReadEntity()

    if not IsValid(target) then
        return
    end

    local transfer = net.ReadUInt(24)

    if transfer > character:GetBankAmount() then
        return
    end

    local targChar = target:GetCharacter()

    targChar:SetBankAmount(targChar:GetBankAmount() + transfer)
    character:SetBankAmount(character:GetBankAmount() - transfer)

    local textMoney = ix.currency.Get(transfer)
    ply:Notify("Successfull transfered " .. textMoney .. " to " .. targChar:GetName())
    target:Notify("You have received a transfer for the amount " .. textMoney)
end)

net.Receive("Bank.Rob", function(_, ply)
    local isStart = net.ReadBool()
    local npc = net.ReadEntity()

    if isStart and not npc:GetRobbing() and PLUGIN.config.robbing[ply:Team()] and ply:IsAdmin() then
        timer.Simple(5, function()
            npc:EmitSound("ambient/explosions/explode_1.wav")
            ix.chat.Send(nil, "robbing", "started robbing bank!")
        end)

        npc:SetRobbing(true)
    elseif not isStart and npc:GetRobbing() then
        npc:SetRobbing(nil)
        ix.chat.Send(nil, "robbing", "finished robbink bank!")
        ply:GetCharacter():GiveMoney(PLUGIN.config.robbingMoney)
    end
end)