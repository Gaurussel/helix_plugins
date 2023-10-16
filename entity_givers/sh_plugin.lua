PLUGIN.name = "Entity givers"
PLUGIN.author = "gaurussel"
PLUGIN.description = "bank for antep7capone"

PLUGIN.config = {
    acceptable = {
        ["STEAM_0:0:115197325"] = true,
    },
}

ix.util.Include("cl_plugin.lua")
ix.util.Include("sv_plugin.lua")