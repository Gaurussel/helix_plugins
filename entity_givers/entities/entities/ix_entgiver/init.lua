AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local PLUGIN = PLUGIN

function ENT:Initialize()
	self:SetModel("models/props_lab/cactus.mdl")
	self:SetSolid(SOLID_BBOX)
	self:SetUseType(SIMPLE_USE)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:CapabilitiesAdd(CAP_ANIMATEDFACE)
	self:SetDisplayName("Giver")
end

local function FormatTime(time)
	local hours = math.floor(time / 3600)
	local minutes = math.floor((time % 3600) / 60)
	local seconds = time % 60
	local formattedTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

	return formattedTime
end

function ENT:CanAccess(client)
	local steamid = client:SteamID()
	local entindex = self:EntIndex()
	if not PLUGIN.config.acceptable[steamid] then return false end

	if PLUGIN.gived[entindex] and PLUGIN.gived[entindex][steamid] and PLUGIN.gived[entindex][steamid] > os.time() then
		client:Notify("You will be able to take the item through " .. FormatTime(os.difftime(PLUGIN.gived[entindex][steamid], os.time())))

		return false
	end

	return true
end

function ENT:Use(activator)
	if not self:CanAccess(activator) then return end
	local inventory = activator:GetCharacter():GetInventory()
	if not inventory:Add(self.item, 1) then return end
	PLUGIN.gived[self:EntIndex()] = PLUGIN.gived[self:EntIndex()] or {}
	PLUGIN.gived[self:EntIndex()][activator:SteamID()] = os.time() + 21600
	activator:Notify("You took an item from the drawer")
end