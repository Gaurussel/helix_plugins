include("shared.lua")
ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
    local name = tooltip:AddRow("name")
    name:SetImportant()
    name:SetText("Bank")
    name:SizeToContents()
end

function ENT:Draw()
    self:DrawModel()
end

net.Receive("Bank.Open", function()
    local panel = vgui.Create("ixBank")
    panel:SetNPC(net.ReadEntity())
    panel:MainScreen(ply, character)
end)