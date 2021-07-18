local PLUGIN = PLUGIN
local ticktime = 0

PLUGIN.name = "Lifes System"
PLUGIN.author = "Gaurussel"
PLUGIN.description = "Blocking a character after the expiration of lives"

ix.lang.AddTable("english", {
	countoflifes = "Lives",
	livesover = "You've run out of all lives"
})

ix.lang.AddTable("russian", {
	countoflifes = "Жизни",
	livesover = "У вас кончились все жизни"
})

if SERVER then
	function PLUGIN:PlayerDeath(ply)
	    local character = ply:GetCharacter()
	    if (character) then
	        local deaths = character:GetData("deathCount", 0) + 1
	        if (deaths >= 3) then
	            character:Ban()
	            netstream.Start(ply, "permadeath.notify")
	        else
	            character:SetData("deathCount", deaths)
	        end
	    end
	end

	function PLUGIN:PlayerTick(ply)
		if ticktime > CurTime() then return end
		ticktime = CurTime() + 1000
		local character = ply:GetCharacter()
		if character then
			local deaths = character:GetData("deathCount", 0)
			if deaths > 0 then
				character:SetData("deathCount", deaths - 1)
			end
		end
	end
end

if CLIENT then//❤ ix.gui.characterMenu
	function PLUGIN:CreateCharacterInfo(panel)
		self.infoRow = panel:Add("ixListRow")
		self.infoRow:SetList(panel.list)
		self.infoRow:Dock(TOP)
	end

	function PLUGIN:UpdateCharacterInfo(panel, char)
		if (self.infoRow) then
			local lives = "❤❤❤"
			self.infoRow:SetLabelText(L("countoflifes"))
			self.infoRow:SetText(utf8.sub(lives, 1, 3-char:GetData("deathCount", 0)))
			self.infoRow:SizeToContents()
		end
	end

	netstream.Hook("permadeath.notify", function()
		timer.Simple(2, function()
			ix.gui.characterMenu:ShowNotice(3, L("livesover"))
		end)
	end)
end