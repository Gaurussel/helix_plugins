ENT.Type = "ai"
ENT.Base = "base_anim"
ENT.PrintName = "Bank"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar( "Bool", 0, "Robbing" )
end