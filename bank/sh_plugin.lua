PLUGIN.name = "Bank"
PLUGIN.author = "gaurussel"
PLUGIN.description = "bank for annabethsssss"

PLUGIN.config = {
    robbing = {
        [FACTION_CITIZEN] = true,
    },
    robbingMoney = 100000,
    materials = {
        background = Material("background.png", "noclamp smooth"),
        input_frame = Material("input_frame.png", "noclamp smooth")
    },
    colors = {
        text = Color(0, 0, 0, 255),
        white = Color(255, 255, 255, 255)
    }
}

ix.util.Include("sv_plugin.lua")

ix.char.RegisterVar("BankAmount", {
    field = "bankamount",
    fieldType = ix.type.number,
    default = 0,
    isLocal = false,
    bNoDisplay = true
})

ix.chat.Register("robbing", {
    CanSay = function(self, speaker, text) return not IsValid(speaker) end,
    CanHear = function() return true end,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(Color(255, 50, 50), "[Robbing] ", color_white, text)
    end,
    noSpaceAfter = true
})