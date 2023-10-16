include("shared.lua")
ENT.PopulateEntityInfo = true

function ENT:OnPopulateEntityInfo(tooltip)
    local name = tooltip:AddRow("name")
    name:SetImportant()
    name:SetText(self:GetDisplayName())
    name:SizeToContents()
end

function ENT:Draw()
    self:DrawModel()
end