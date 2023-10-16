local PLUGIN = PLUGIN

local function ss(px)
    return px * ScrH() / 1080
end

surface.CreateFont("ixBankFont", {
    font = "Blakstone",
    size = ss(36),
    weight = 700,
    extended = true
})

local PANEL = {}

AccessorFunc(PANEL, "npc", "NPC")

function PANEL:Init()
    self:AlphaTo(0, 0)
    self:SetSize(ScrW() * .65, ScrH() * .65)
    self:MakePopup()
    self:Center()

    local wide, tall = self:GetWide(), self:GetTall()

    self.container = self:Add("DScrollPanel")
    self.container:SetPos(0, 0)
    self.container:SetSize(wide, tall)
end

function PANEL:MainScreen()
    self:AlphaTo(0, 0.15)
    self.container:Clear()
    local ply = LocalPlayer()
    local character = ply:GetCharacter()
    self.container.bankAmount = character:GetBankAmount()

    local wide, tall = self:GetWide(), self:GetTall()
    local bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("HESABIM")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .5, (tall - bankNumberLabel:GetTall()) * .35)

    local text = ix.currency.Get(self.container.bankAmount)
    surface.SetFont("ixBankFont")
    local labelwide, labeltall = surface.GetTextSize(text)

    local panelwide, paneltall = labelwide + wide * .1, labeltall + tall * .1
    local bankAmountPanel = self.container:Add("EditablePanel")
    bankAmountPanel:SetSize(panelwide, paneltall)
    bankAmountPanel:SetPos((wide - panelwide) * .5, (tall - paneltall) * .55)
    bankAmountPanel.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)

        draw.SimpleText(text, "ixBankFont", pwide * .5, ptall * .45, PLUGIN.config.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.closeButton = self.container:Add("ixBankButton")
    self.closeButton:SetText("Close")
    self.closeButton:SizeToContents()
    self.closeButton:SetTextColor(PLUGIN.config.colors.text)
    self.closeButton:SetContentAlignment(5)
    self.closeButton:SetPos((wide - panelwide) * .5 + panelwide, (tall - self.closeButton:GetTall()) * .535)
    self.closeButton.DoClick = function()
        self:AlphaTo(0, 0.15, 0, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    end

    local nextThink = CurTime() + 1
    bankAmountPanel.Think = function()
        if nextThink > CurTime() then return end
        nextThink = CurTime() + .25
        self.container.bankAmount = character:GetBankAmount()
        text = ix.currency.Get(self.container.bankAmount)
    end

    local withdraw = self.container:Add("ixBankButton")
    withdraw:SetText("Withdraw")
    withdraw:SizeToContents()
    withdraw:SetTextColor(PLUGIN.config.colors.text)
    withdraw:SetContentAlignment(5)
    withdraw:SetPos((wide - withdraw:GetWide()) * .37, (tall - withdraw:GetTall()) * .7)
    withdraw.DoClick = function()
        self.container:AlphaTo(0, 0.15, 0, function()
            if IsValid(self.container) then
                self.container:Clear()
                self:OpenWithdraw(ply, character)
            end
        end)
    end

    local faction = character:GetFaction()

    if PLUGIN.config.robbing[faction] and ply:IsAdmin() and not self.npc:GetRobbing() then
        local rob = self.container:Add("ixBankButton")
        rob:SetText("RAID Start")
        rob:SizeToContents()
        rob:SetTextColor(PLUGIN.config.colors.text)
        rob:SetContentAlignment(5)
        rob:SetPos((wide - rob:GetWide()) * .02, (tall - rob:GetTall()) * .5)
        rob.DoClick = function()
            self:AlphaTo(0, 0.15, 0, function()
                if IsValid(self) then
                    self:Remove()

                    net.Start("Bank.Rob")
                        net.WriteBool(true)
                        net.WriteEntity(self.npc)
                    net.SendToServer()
                end
            end)
        end
    elseif self.npc:GetRobbing() then
        local rob = self.container:Add("ixBankButton")
        rob:SetText("RAID Stop")
        rob:SizeToContents()
        rob:SetTextColor(PLUGIN.config.colors.text)
        rob:SetContentAlignment(5)
        rob:SetPos((wide - rob:GetWide()) * .02, (tall - rob:GetTall()) * .5)
        rob.DoClick = function()
            self:AlphaTo(0, 0.15, 0, function()
                if IsValid(self) then
                    self:Remove()

                    net.Start("Bank.Rob")
                        net.WriteBool(false)
                        net.WriteEntity(self.npc)
                    net.SendToServer()
                end
            end)
        end
    end

    local deposit = self.container:Add("ixBankButton")
    deposit:SetText("Deposit")
    deposit:SizeToContents()
    deposit:SetTextColor(PLUGIN.config.colors.text)
    deposit:SetContentAlignment(5)
    deposit:SetPos((wide - deposit:GetWide()) * .62, (tall - deposit:GetTall()) * .7)
    deposit.DoClick = function()
        self.container:AlphaTo(0, 0.15, 0, function()
            if IsValid(self.container) then
                self.container:Clear()
                self:OpenDeposit(ply, character)
            end
        end)
    end

    local transfer = self.container:Add("ixBankButton")
    transfer:SetText("transfer")
    transfer:SizeToContents()
    transfer:SetTextColor(PLUGIN.config.colors.text)
    transfer:SetContentAlignment(5)
    transfer:SetPos((wide - transfer:GetWide()) * .5, (tall - transfer:GetTall()) * .85)
    transfer.DoClick = function()
        self.container:AlphaTo(0, 0.15, 0, function()
            if IsValid(self.container) then
                self.container:Clear()
                self:OpenTransfer(ply, character)
            end
        end)
    end

    self:AlphaTo(255, 0.15)
end

function PANEL:OpenDeposit(ply, character)
    self.container:AlphaTo(255, 0.15)
    local wide, tall = self:GetWide(), self:GetTall()
    local bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("HESABIM")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .86, (tall - bankNumberLabel:GetTall()) * .75)

    local text = ix.currency.Get(self.container.bankAmount)
    surface.SetFont("ixBankFont")
    local labelwide, labeltall = surface.GetTextSize(text)

    local panelwide, paneltall = labelwide + wide * .1, labeltall + tall * .1
    local bankAmountPanel = self.container:Add("EditablePanel")
    bankAmountPanel:SetSize(panelwide, paneltall)
    bankAmountPanel:SetPos((wide - panelwide) * .94, (tall - paneltall) * .92)
    bankAmountPanel.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)

        draw.SimpleText(text, "ixBankFont", pwide * .5, ptall * .45, PLUGIN.config.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("MIKTAR")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .5, (tall - bankNumberLabel:GetTall()) * .35)

    local wangwide, wangtall = wide * .2, tall * .15
    local parentText = self.container:Add("EditablePanel")
    parentText:SetSize(wangwide, wangtall)
    parentText:SetPos((wide - wangwide) * .5, (tall - wangtall) * .6)

    local Wang = parentText:Add("DNumberWang")
    Wang:SetFont("ixBankFont")
    Wang:Dock(FILL)
    Wang:DockMargin(30, 15, 30, 15)
    Wang:SetPaintBackground(false)
    Wang:SetContentAlignment(5)
    Wang:HideWang()
    Wang:SetTextColor(PLUGIN.config.colors.text)
    parentText.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)
    end

    local Deposit = self.container:Add("ixBankButton")
    Deposit:SetText("Deposit")
    Deposit:SizeToContents()
    Deposit:SetTextColor(PLUGIN.config.colors.text)
    Deposit:SetContentAlignment(5)
    Deposit:SetPos((wide - Deposit:GetWide()) * .5, (tall - Deposit:GetTall()) * .85)
    Deposit.DoClick = function()
        if character:GetMoney() < Wang:GetValue() then
            ply:Notify("No money!")
            return
        end

        self.container.bankAmount = self.container.bankAmount + Wang:GetValue()

        net.Start("Bank.Deposit")
            net.WriteUInt(Wang:GetValue(), 24)
        net.SendToServer()

        self:MainScreen(ply, character)
    end

    local MainScreen = self.container:Add("ixBankButton")
    MainScreen:SetText("Back")
    MainScreen:SizeToContents()
    MainScreen:SetTextColor(PLUGIN.config.colors.text)
    MainScreen:SetContentAlignment(5)
    MainScreen:SetPos((wide - MainScreen:GetWide()) * .65, (tall - MainScreen:GetTall()) * .585)
    MainScreen.DoClick = function()
        self:MainScreen(ply, character)
    end
end

function PANEL:OpenWithdraw(ply, character)
    self.container:AlphaTo(255, 0.15)
    local wide, tall = self:GetWide(), self:GetTall()
    local bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("HESABIM")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .86, (tall - bankNumberLabel:GetTall()) * .75)

    local text = ix.currency.Get(self.container.bankAmount)
    surface.SetFont("ixBankFont")
    local labelwide, labeltall = surface.GetTextSize(text)

    local panelwide, paneltall = labelwide + wide * .1, labeltall + tall * .1
    local bankAmountPanel = self.container:Add("EditablePanel")
    bankAmountPanel:SetSize(panelwide, paneltall)
    bankAmountPanel:SetPos((wide - panelwide) * .94, (tall - paneltall) * .92)
    bankAmountPanel.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)

        draw.SimpleText(text, "ixBankFont", pwide * .5, ptall * .45, PLUGIN.config.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("MIKTAR")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .5, (tall - bankNumberLabel:GetTall()) * .35)

    local wangwide, wangtall = wide * .2, tall * .15
    local parentText = self.container:Add("EditablePanel")
    parentText:SetSize(wangwide, wangtall)
    parentText:SetPos((wide - wangwide) * .5, (tall - wangtall) * .6)

    local Wang = parentText:Add("DNumberWang")
    Wang:SetFont("ixBankFont")
    Wang:Dock(FILL)
    Wang:SetTextColor(PLUGIN.config.colors.text)
    Wang:DockMargin(30, 15, 30, 15)
    Wang:SetPaintBackground(false)
    Wang:SetContentAlignment(5)
    Wang:HideWang()
    parentText.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)
    end

    local Withdraw = self.container:Add("ixBankButton")
    Withdraw:SetText("Withdraw")
    Withdraw:SizeToContents()
    Withdraw:SetTextColor(PLUGIN.config.colors.text)
    Withdraw:SetContentAlignment(5)
    Withdraw:SetPos((wide - Withdraw:GetWide()) * .5, (tall - Withdraw:GetTall()) * .85)
    Withdraw.DoClick = function()
        if self.container.bankAmount < Wang:GetValue() then
            ply:Notify("No money!")
            return
        end

        self.container.bankAmount = self.container.bankAmount - Wang:GetValue()
        text = ix.currency.Get(self.container.bankAmount)

        net.Start("Bank.Withdraw")
            net.WriteUInt(Wang:GetValue(), 24)
        net.SendToServer()

        self:MainScreen(ply, character)
    end

    local MainScreen = self.container:Add("ixBankButton")
    MainScreen:SetText("Back")
    MainScreen:SizeToContents()
    MainScreen:SetTextColor(PLUGIN.config.colors.text)
    MainScreen:SetContentAlignment(5)
    MainScreen:SetPos((wide - MainScreen:GetWide()) * .65, (tall - MainScreen:GetTall()) * .6)
    MainScreen.DoClick = function()
        self:MainScreen(ply, character)
    end
end

function PANEL:OpenTransfer(ply, character)
    self.container:AlphaTo(255, 0.15)
    local wide, tall = self:GetWide(), self:GetTall()
    local bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("HESABIM")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .86, (tall - bankNumberLabel:GetTall()) * .75)

    local text = ix.currency.Get(self.container.bankAmount)
    surface.SetFont("ixBankFont")
    local labelwide, labeltall = surface.GetTextSize(text)

    local panelwide, paneltall = labelwide + wide * .1, labeltall + tall * .1
    local bankAmountPanel = self.container:Add("EditablePanel")
    bankAmountPanel:SetSize(panelwide, paneltall)
    bankAmountPanel:SetPos((wide - panelwide) * .94, (tall - paneltall) * .92)
    bankAmountPanel.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)

        draw.SimpleText(text, "ixBankFont", pwide * .5, ptall * .45, PLUGIN.config.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    bankNumberLabel = self.container:Add("DLabel")
    bankNumberLabel:SetText("MIKTAR")
    bankNumberLabel:SetFont("ixBankFont")
    bankNumberLabel:SizeToContents()
    bankNumberLabel:SetColor(PLUGIN.config.colors.text)
    bankNumberLabel:SetPos((wide - bankNumberLabel:GetWide()) * .5, (tall - bankNumberLabel:GetTall()) * .35)

    local selectedID = 0
    local playerswide, playerstall = wide * .2, tall * .15

    local players = self.container:Add("DComboBox")
    players:SetValue( "Select player" )
    players:SetFont("ixBankFont")
    -- players:SizeToContents()
    players:SetSize(playerswide, playerstall)
    players:SetContentAlignment(5)
    players:SetPos( (wide - playerswide) * .5, (tall - playerstall) * .5 )
    players:SetTextColor(PLUGIN.config.colors.text)
    players.DropButton.Paint = function()
    end
    players.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)
    end

    players.OnSelect = function(this, index, val, data)
        selectedID = data
    end

    for _, target in ipairs(player.GetAll()) do
        if target == ply then
            continue
        end

        local targetChar = target.GetCharacter and target:GetCharacter()

        if not targetChar then
            continue
        end

        players:AddChoice(targetChar:GetName(), target)
    end

    local wangwide, wangtall = wide * .23, tall * .16
    local parentText = self.container:Add("EditablePanel")
    parentText:SetSize(wangwide, wangtall)
    parentText:SetPos((wide - wangwide) * .5, (tall - wangtall) * .7)

    local Wang = parentText:Add("DNumberWang")
    Wang:SetFont("ixBankFont")
    Wang:Dock(FILL)
    Wang:DockMargin(30, 15, 30, 15)
    Wang:SetPaintBackground(false)
    Wang:SetContentAlignment(5)
    Wang:HideWang()
    Wang:SetTextColor(PLUGIN.config.colors.text)
    parentText.Paint = function(this, pwide, ptall)
        surface.SetDrawColor(PLUGIN.config.colors.white)
        surface.SetMaterial(PLUGIN.config.materials.input_frame)
        surface.DrawTexturedRect(0, 0, pwide, ptall)
    end

    local Transfer = self.container:Add("ixBankButton")
    Transfer:SetText("Transfer")
    Transfer:SizeToContents()
    Transfer:SetTextColor(PLUGIN.config.colors.text)
    Transfer:SetContentAlignment(5)
    Transfer:SetPos((wide - Transfer:GetWide()) * .5, (tall - Transfer:GetTall()) * .85)
    Transfer.DoClick = function()
        if self.container.bankAmount < Wang:GetValue() then
            ply:Notify("No money!")
            return
        end

        if selectedID == 0 then
            ply:Notify("Select player!")
            return
        end

        self.container.bankAmount = self.container.bankAmount - Wang:GetValue()
        text = ix.currency.Get(self.container.bankAmount)

        net.Start("Bank.Transfer")
            net.WriteEntity(selectedID)
            net.WriteUInt(Wang:GetValue(), 24)
        net.SendToServer()

        self:MainScreen(ply, character)
    end

    local MainScreen = self.container:Add("ixBankButton")
    MainScreen:SetText("Back")
    MainScreen:SizeToContents()
    MainScreen:SetTextColor(PLUGIN.config.colors.text)
    MainScreen:SetContentAlignment(5)
    MainScreen:SetPos((wide - MainScreen:GetWide()) * .68, (tall - MainScreen:GetTall()) * .58)
    MainScreen.DoClick = function()
        self:MainScreen(ply, character)
    end
end

function PANEL:Paint(wide, tall)
    surface.SetDrawColor(PLUGIN.config.colors.white)
    surface.SetMaterial(PLUGIN.config.materials.background)
    surface.DrawTexturedRect(0, 0, wide, tall)
end

vgui.Register("ixBank", PANEL, "EditablePanel")