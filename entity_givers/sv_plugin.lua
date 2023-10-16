util.AddNetworkString("GIVERS.Edit")
local PLUGIN = PLUGIN
PLUGIN.entities = PLUGIN.entities or {}
PLUGIN.gived = PLUGIN.gived or {}

hook.Add("InitPostEntity", "givers", function()
    local entities = ix.data.Get("givers", {})
    for uniqueID, v in ipairs(entities) do
        local entity = ents.Create("ix_entgiver")
        entity:SetPos(Vector(v.position.vector))
        entity:SetAngles(Angle(v.position.angles))
        entity:Spawn()

        entity:SetModel(v.model)
        entity:SetDisplayName(v.name)
        entity.item = v.item
        PLUGIN.entities[entity:EntIndex()] = entity
    end
end)

concommand.Add("giver.edit", function(ply)
    local ent = ply:GetEyeTrace().Entity
    if not ply:IsSuperAdmin() or not IsValid(ent) then
        return
    end

    net.Start("GIVERS.Edit")
        net.WriteEntity(ent)

    if PLUGIN.entities[ent:EntIndex()] then
        net.WriteString(ent:GetDisplayName())
        net.WriteString(ent.item or "")
    end

    net.Send(ply)
end)

net.Receive("GIVERS.Edit", function(_, ply)
    if not ply:IsSuperAdmin() then
        return
    end

    local name = net.ReadString()
    local item = net.ReadString()
    local model = net.ReadString()
    local ent = net.ReadEntity()

    ent.item = item
    ent:SetDisplayName(name)
    ent:SetModel(model)

    local id = ent:EntIndex()
    PLUGIN.entities[id] = ent
end)

concommand.Add("giver.save", function(ply)
    if not ply:IsSuperAdmin() then
        return
    end

    local entities = {}
    for id, ent in ipairs(ents.FindByClass("ix_entgiver")) do
        entities[#entities + 1] = {
            name = ent:GetDisplayName(),
            model = ent:GetModel(),
            item = ent.item or "",
            position = {
                vector = ent:GetPos(),
                angles = ent:GetAngles()
            }
        }
    end

    ix.data.Set("givers", entities)
end)