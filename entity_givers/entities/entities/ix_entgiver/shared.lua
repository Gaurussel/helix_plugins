ENT.Type = "ai"
ENT.Base = "base_anim"
ENT.PrintName = "Giver by SteamID"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "DisplayName")
end