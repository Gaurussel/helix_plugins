local errorModel = "models/player/skeleton.mdl"
local PANEL = {}
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)

local function SetCharacter(self, character)
	self.character = character

	if character then
		self:SetModel(character:GetModel())
		self:SetSkin(character:GetData("skin", 0))

		for i = 0, self:GetNumBodyGroups() - 1 do
			self:SetBodygroup(i, 0)
		end

		local bodygroups = character:GetData("groups", nil)

		if istable(bodygroups) then
			for k, v in pairs(bodygroups) do
				self:SetBodygroup(k, v)
			end
		end
	else
		self:SetModel(errorModel)
	end
end

local function GetCharacter(self)
	return self.character
end

function PANEL:Init()
	self.activeCharacter = ClientsideModel(errorModel)
	self.activeCharacter:SetNoDraw(true)
	self.activeCharacter.SetCharacter = SetCharacter
	self.activeCharacter.GetCharacter = GetCharacter
	self.lastCharacter = ClientsideModel(errorModel)
	self.lastCharacter:SetNoDraw(true)
	self.lastCharacter.SetCharacter = SetCharacter
	self.lastCharacter.GetCharacter = GetCharacter
	self.animationTime = 0.5
	self.shadeY = 0
	self.shadeHeight = 0
	self.cameraPosition = Vector(80, 0, 35)
	self.cameraAngle = Angle(0, 180, 0)
	self.lastPaint = 0
end

function PANEL:ResetSequence(model, lastModel)
	local sequence = model:LookupSequence("lineidle0" .. math.random(1, 4))

	if sequence <= 0 then
		sequence = model:SelectWeightedSequence(ACT_IDLE)
	end

	if sequence > 0 then
		model:ResetSequence(sequence)
	else
		local found = false

		for _, v in ipairs(model:GetSequenceList()) do
			if (v:lower():find("idle") or v:lower():find("fly")) and v ~= "idlenoise" then
				model:ResetSequence(v)
				found = true
				break
			end
		end

		if not found then
			model:ResetSequence(4)
		end
	end

	model:SetIK(false)

	if lastModel then
		model:ResetSequence(sequence)
		model:SetCycle(lastModel:GetCycle())
	end
end

function PANEL:RunAnimation(model)
	model:FrameAdvance((RealTime() - self.lastPaint) * 1)
end

function PANEL:LayoutEntity(model)
	model:SetIK(false)
	self:RunAnimation(model)
end

function PANEL:SetActiveCharacter(character)
	self.shadeY = self:GetTall()
	self.shadeHeight = self:GetTall()

	if self.activeCharacter:GetModel() == errorModel then
		self.activeCharacter:SetCharacter(character)
		self:ResetSequence(self.activeCharacter)

		return
	end

	local shade = self:GetTweenAnimation(1)
	local shadeHide = self:GetTweenAnimation(2)

	if shade then
		shade.newCharacter = character

		return
	elseif shadeHide then
		shadeHide.queuedCharacter = character

		return
	end

	self.lastCharacter:SetCharacter(self.activeCharacter:GetCharacter())
	self:ResetSequence(self.lastCharacter, self.activeCharacter)

	shade = self:CreateAnimation(self.animationTime * 0.5, {
		index = 1,
		target = {
			shadeY = 0,
			shadeHeight = self:GetTall()
		},
		easing = "linear",
		OnComplete = function(shadeAnimation, shadePanel)
			shadePanel.activeCharacter:SetCharacter(shadeAnimation.newCharacter)
			shadePanel:ResetSequence(shadePanel.activeCharacter)

			shadePanel:CreateAnimation(shadePanel.animationTime, {
				index = 2,
				target = {
					shadeHeight = 0
				},
				easing = "outQuint",
				OnComplete = function(animation, panel)
					if animation.queuedCharacter then
						panel:SetActiveCharacter(animation.queuedCharacter)
					else
						panel.lastCharacter:SetCharacter(nil)
					end
				end
			})
		end
	})

	shade.newCharacter = character
end

function PANEL:Paint(width, height)
	local x, y = self:LocalToScreen(0, 0)
	local bTransition = self.lastCharacter:GetModel() ~= errorModel
	local modelFOV = (ScrW() > ScrH() * 1.8) and 92 or 70
	cam.Start3D(self.cameraPosition, self.cameraAngle, modelFOV, x, y, width, height)
	render.SuppressEngineLighting(true)
	render.SetLightingOrigin(self.activeCharacter:GetPos())
	-- setup lighting
	render.SetModelLighting(0, 1.5, 1.5, 1.5)

	for i = 1, 4 do
		render.SetModelLighting(i, 0.4, 0.4, 0.4)
	end

	render.SetModelLighting(5, 0.04, 0.04, 0.04)
	-- clip anything out of bounds
	local curparent = self
	local rightx = self:GetWide()
	local leftx = 0
	local topy = 0
	local bottomy = self:GetTall()
	local previous = curparent

	while curparent:GetParent() ~= nil do
		local lastX, lastY = previous:GetPos()
		curparent = curparent:GetParent()
		topy = math.Max(lastY, topy + lastY)
		leftx = math.Max(lastX, leftx + lastX)
		bottomy = math.Min(lastY + previous:GetTall(), bottomy + lastY)
		rightx = math.Min(lastX + previous:GetWide(), rightx + lastX)
		previous = curparent
	end

	ix.util.ResetStencilValues()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(30)
	render.SetStencilTestMask(30)
	render.SetStencilReferenceValue(31)
	render.SetStencilCompareFunction(STENCIL_ALWAYS)
	render.SetStencilPassOperation(STENCIL_REPLACE)
	render.SetStencilFailOperation(STENCIL_KEEP)
	render.SetStencilZFailOperation(STENCIL_KEEP)
	self:LayoutEntity(self.activeCharacter)

	if bTransition then
		self:LayoutEntity(self.lastCharacter)
		render.SetScissorRect(leftx, topy, rightx, bottomy - (self:GetTall() - self.shadeHeight), true)
		self.lastCharacter:DrawModel()
		render.SetScissorRect(leftx, topy + self.shadeHeight, rightx, bottomy, true)
		self.activeCharacter:DrawModel()
		render.SetScissorRect(leftx, topy, rightx, bottomy, true)
	else
		self.activeCharacter:DrawModel()
	end

	render.SetStencilCompareFunction(STENCIL_EQUAL)
	render.SetStencilPassOperation(STENCIL_KEEP)
	cam.Start2D()
	derma.SkinFunc("PaintCharacterTransitionOverlay", self, 0, self.shadeY, width, self.shadeHeight)
	cam.End2D()
	render.SetStencilEnable(false)
	render.SetScissorRect(0, 0, 0, 0, false)
	render.SuppressEngineLighting(false)
	cam.End3D()
	self.lastPaint = RealTime()
end

function PANEL:OnRemove()
	self.lastCharacter:Remove()
	self.activeCharacter:Remove()
end

vgui.Register("ixCharMenuCarousel", PANEL, "Panel")
-- character load panel
PANEL = {}
AccessorFunc(PANEL, "animationTime", "AnimationTime", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundFraction", "BackgroundFraction", FORCE_NUMBER)

function PANEL:Init()
	local parent = self:GetParent()
	local padding = self:GetPadding()
	local halfWidth = parent:GetWide() * 0.5 - (padding * 2)
	local halfHeight = parent:GetTall() * 0.5 - (padding * 2)
	local modelFOV = (ScrW() > ScrH() * 1.8) and 102 or 78
	self.character = ix.char.loaded[ix.characters[1]]
	self.characterid = 1
	self.characterAttrib = {}
	self.animationTime = 1
	self.backgroundFraction = 1
	-- main panel
	self.panel = self:AddSubpanel("main")
	self.panel:SetTitle("")
	self.panel.OnSetActive = function()
		self:CreateAnimation(self.animationTime, {
			index = 2,
			target = {
				backgroundFraction = 1
			},
			easing = "outQuint",
		})

		self.carousel:SetActiveCharacter(self.character)
	end

	local wide, tall = self:GetWide(), self:GetTall()

	local dscSubPanel = self.panel:Add("Panel")
	dscSubPanel:SetSize(wide * .25, tall * .45)
	dscSubPanel:SetPos(wide * .05, (tall - dscSubPanel:GetTall()) * .35)

	local config_color = ix.config.Get("color")
	local color_black_1 = Color(0, 0, 0, 80)
	local color_black_2 = Color(0, 0, 0, 129)
	dscSubPanel.Paint = function(panel, width, height)
		surface.SetDrawColor(color_black_1)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(config_color)
		surface.DrawRect(1, height * .1, width - 2, height * .005)

		surface.SetDrawColor(color_black_2)
		surface.DrawOutlinedRect(0, 0, width, height, height * .005)
	end

	if not self.character then return end
	local index = self.character:GetFaction()
	local faction = ix.faction.indices[index]
	local color = faction and faction.color or color_white

	local charName = dscSubPanel:Add("DLabel")
	charName:Dock(TOP)
	charName:SetTall(dscSubPanel:GetTall() * .1)
	charName:SetText(self.character:GetName())
	charName:SetFont("ixMenuButtonFont")
	charName:SetTextColor(color)
	charName:SetContentAlignment(5)

	local charDesc = dscSubPanel:Add("DLabel")
	charDesc:SetWrap(true)
	charDesc:Dock(FILL)
	charDesc:SetFont("ixMenuButtonFont")
	charDesc:SetText(self.character:GetDescription())
	charDesc:DockMargin(5, 5, 5, 0)
	charDesc:SetTextColor(color_white)
	charDesc:SetContentAlignment(8)

	local perkSubPanel = self.panel:Add("Panel")
	perkSubPanel:SetSize(wide * .25, tall * .45)
	perkSubPanel:SetPos((wide - perkSubPanel:GetWide()) * .8, (tall - dscSubPanel:GetTall()) * .35)

	perkSubPanel.PaintOver = function(panel, width, height)
		surface.SetDrawColor(color_black_1)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(config_color)
		surface.DrawRect(1, height * .1, width - 2, height * .005)

		surface.SetDrawColor(color_black_2)
		surface.DrawOutlinedRect(0, 0, width, height, height * .005)
	end

	local perkTitle = perkSubPanel:Add("DLabel")
	perkTitle:SetText(L("attributes"))
	perkTitle:Dock(TOP)
	perkTitle:SetTall(perkSubPanel:GetTall() * .1)
	perkTitle:DockMargin(5, 5, 5, 0)
	perkTitle:SetFont("ixMenuButtonFont")
	perkTitle:SetTextColor(color_white)
	perkTitle:SetContentAlignment(8)

	local perksPanel = perkSubPanel:Add("DScrollPanel")
	perksPanel:Dock(TOP)
	perksPanel:SetTall(perkSubPanel:GetTall() - perkTitle:GetTall())

	local boost = self.character:GetBoosts()

	for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
		local attributeBoost = 0

		if boost[k] then
			for _, bValue in pairs(boost[k]) do
				attributeBoost = attributeBoost + bValue
			end
		end

		local bar = perksPanel:Add("ixAttributeBar")
		bar:Dock(TOP)
		bar:DockMargin(5, 5, 5, 0)

		local value = self.character:GetAttribute(k, 0)

		if attributeBoost then
			bar:SetValue(value - attributeBoost or 0)
		else
			bar:SetValue(value)
		end

		local maximum = v.maxValue or ix.config.Get("maxAttributes", 100)
		bar:SetMax(maximum)
		bar:SetReadOnly()
		bar:SetTall(tall * .045)
		bar:SetText(Format("%s (%.1f%%)", L(v.name), value / maximum * 100))

		if attributeBoost then
			bar:SetBoost(attributeBoost)
		end

		table.insert(self.characterAttrib, bar)
	end

	local infoPanel = self.panel:Add("Panel")
	infoPanel:SetSize(wide * .8, tall * .15)
	infoPanel:SetPos(wide * .05, (tall - infoPanel:GetTall()) * .8)

	local infoButtons = infoPanel:Add("Panel")
	infoButtons:Dock(BOTTOM)
	infoButtons:SetTall(tall * .05)
	infoButtons:DockMargin(0, 0, 0, 10)

	local continueButton = infoButtons:Add("ixMenuButton")
	continueButton:Dock(RIGHT)
	continueButton:SetText(L("choose"))
	continueButton:SizeToContents()
	continueButton:SetContentAlignment(5)
	continueButton:SetTextInset(0, 0)
	continueButton:SizeToContents()

	continueButton.DoClick = function()
		self:SetMouseInputEnabled(false)

		self:Slide("down", self.animationTime * 2, function()
			net.Start("ixCharacterChoose")
			net.WriteUInt(self.character:GetID(), 32)
			net.SendToServer()
		end, true)
	end

	continueButton.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(0, 0, 0, 129)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local back = infoButtons:Add("ixMenuButton")
	back:Dock(LEFT)
	back:SetText("return")
	back:SizeToContents()
	back:SetContentAlignment(5)
	back:SetTextInset(0, 0)
	back:SizeToContents()

	back.DoClick = function()
		self:SlideDown()
		parent.mainPanel:Undim()
	end

	back.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(Color(0, 0, 0, 129))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local removeCharacter = infoButtons:Add("ixMenuButton")
	removeCharacter:Dock(LEFT)
	removeCharacter:SetText("delete")
	removeCharacter:SizeToContents()
	removeCharacter:DockMargin(10, 0, 0, 0)
	removeCharacter:SetContentAlignment(5)
	removeCharacter:SetTextInset(0, 0)
	removeCharacter:SizeToContents()

	removeCharacter.DoClick = function()
		self:SetActiveSubpanel("delete")
	end

	removeCharacter.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(Color(0, 0, 0, 129))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	self.carousel = self.panel:Add("ixCharMenuCarousel")
	self.carousel:SetSize(wide * .5, tall * .75)
	self.carousel:Center()
	self.carousel:SetActiveCharacter(self.character)

	self.delete = self:AddSubpanel("delete")
	self.delete:SetZPos(1)
	self.delete:SetTitle(nil)

	self.delete.OnSetActive = function(p)
		self.deleteModel:SetModel(self.character:GetModel())
		self:CreateAnimation(self.animationTime, {
			index = 2,
			target = {
				backgroundFraction = 0
			},
			easing = "outQuint"
		})
	end

	local deleteInfo = self.delete:Add("Panel")
	deleteInfo:SetSize(parent:GetWide() * 0.5, parent:GetTall())
	deleteInfo:Dock(LEFT)

	local deleteReturn = deleteInfo:Add("ixMenuButton")
	deleteReturn:SetText("NO! What am I doing - Go back!")
	deleteReturn:SizeToContents()
	deleteReturn:SetZPos(100)
	deleteReturn:SetPos((deleteInfo:GetWide() - deleteReturn:GetWide()) * .15, (deleteInfo:GetTall() - deleteReturn:GetTall()) * .803)

	deleteReturn.DoClick = function()
		self:SetActiveSubpanel("main")
	end

	deleteReturn.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)

		surface.SetDrawColor(0, 0, 0, 129)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local deleteConfirm = self.delete:Add("ixMenuButton")
	deleteConfirm:SetText("Yes - I want to remove this character!")
	deleteConfirm:SizeToContents()
	deleteConfirm:SetPos((self.delete:GetWide() - deleteConfirm:GetWide()) * .85, (self.delete:GetTall() - deleteConfirm:GetTall()) * .987)
	deleteConfirm:SetZPos(100)
	deleteConfirm:SetTextColor(derma.GetColor("Error", deleteConfirm))

	deleteConfirm.DoClick = function()
		local id = self.character:GetID()
		parent:ShowNotice(1, L("deleteComplete", self.character:GetName()))
		self:Populate(id)
		self:SetActiveSubpanel("main")
		net.Start("ixCharacterDelete")
		net.WriteUInt(id, 32)
		net.SendToServer()
	end

	deleteConfirm.PaintOver = function(panel, width, height)
		surface.SetDrawColor(31, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(Color(0, 0, 0, 129))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	self.deleteModel = deleteInfo:Add("DModelPanel")
	self.deleteModel:Dock(FILL)
	self.deleteModel:SetModel(errorModel)
	self.deleteModel:SetZPos(10)
	self.deleteModel:SetFOV(modelFOV)
	self.deleteModel.PaintModel = self.deleteModel.Paint

	local deleteNag = self.delete:Add("Panel")
	deleteNag:SetTall(parent:GetTall() * 0.5)
	deleteNag:Dock(BOTTOM)

	local deleteTitle = deleteNag:Add("DLabel")
	deleteTitle:SetFont("ixTitleFont")
	deleteTitle:SetText(L("areYouSure"):utf8upper())
	deleteTitle:SetTextColor(ix.config.Get("color"))
	deleteTitle:SizeToContents()
	deleteTitle:Dock(TOP)

	local deleteText = deleteNag:Add("DLabel")
	deleteText:SetFont("ixMenuButtonFont")
	deleteText:SetText(L("deleteConfirm"))
	deleteText:SetTextColor(color_white)
	deleteText:SetContentAlignment(7)
	deleteText:Dock(FILL)

	local preCharButton = self.panel:Add("ixMenuButton")
	preCharButton:SetSize(wide * .025, tall * .45)
	preCharButton:SetPos(dscSubPanel:GetWide() + wide * .05 + preCharButton:GetWide() * .25, (tall - preCharButton:GetTall()) * .35)
	preCharButton:SetText("<")
	preCharButton:SetContentAlignment(5)

	preCharButton.DoClick = function()
		local bUpdate = false
		for i = 1, #ix.characters do
			local id = ix.characters[i]
			local character = ix.char.loaded[id]
			if not character or character:GetID() == ignoreID then continue end
			local index = character:GetFaction()
			local faction = ix.faction.indices[index]
			local color = faction and faction.color or color_white

			if self.character ~= character then
				if (self.characterid - 1 or 0) == i then
					local character = ix.char.loaded[ix.characters[i]]
					self.carousel:SetActiveCharacter(character)
					self.character = character
					self.characterid = i
					charName:SetTextColor(color)
					charName:SetText(character:GetName())
					charDesc:SetText(character:GetDescription())
					charDesc:SizeToContents()
					bUpdate = true
					break
				end
			end
		end

		if bUpdate then
			local boost = self.character:GetBoosts()
			perksPanel:Clear()

			for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
				local attributeBoost = 0

				if boost[k] then
					for _, bValue in pairs(boost[k]) do
						attributeBoost = attributeBoost + bValue
					end
				end

				local bar = perksPanel:Add("ixAttributeBar")
				bar:Dock(TOP)
				bar:DockMargin(5, 5, 5, 0)

				local value = self.character:GetAttribute(k, 0)

				if attributeBoost then
					bar:SetValue(value - attributeBoost or 0)
				else
					bar:SetValue(value)
				end

				local maximum = v.maxValue or ix.config.Get("maxAttributes", 100)
				bar:SetMax(maximum)
				bar:SetReadOnly()
				bar:SetTall(tall * .045)
				--bar:SetText(Format("%s [%.1f/%.1f] (%.1f%%)", L(v.name), value, maximum, value / maximum * 100))
				bar:SetText(Format("%s (%.1f%%)", L(v.name), value / maximum * 100))

				if attributeBoost then
					bar:SetBoost(attributeBoost)
				end

				table.insert(self.characterAttrib, bar)
			end

			bUpdate = false
		end
	end

	preCharButton.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(Color(0, 0, 0, 129))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local nextCharButton = self.panel:Add("ixMenuButton")
	nextCharButton:SetSize(wide * .025, tall * .45)
	nextCharButton:SetPos((wide - perkSubPanel:GetWide()) * .8 - nextCharButton:GetWide() - nextCharButton:GetWide() * .25, (tall - nextCharButton:GetTall()) * .35)
	nextCharButton:SetText(">")
	nextCharButton:SetContentAlignment(5)

	nextCharButton.DoClick = function()
		local bUpdate = false
		for i = 1, #ix.characters do
			local id = ix.characters[i]
			local character = ix.char.loaded[id]
			if not character or character:GetID() == ignoreID then continue end
			local index = character:GetFaction()
			local faction = ix.faction.indices[index]
			local color = faction and faction.color or color_white

			if (self.characterid or 0) < i then
				local character = ix.char.loaded[ix.characters[i]]
				self.carousel:SetActiveCharacter(character)
				self.character = character
				self.characterid = i
				charName:SetTextColor(color)
				charName:SetText(character:GetName())
				charDesc:SetText(character:GetDescription())
				charDesc:SizeToContents()
				bUpdate = true
				break
			end
		end

		if bUpdate then
			local boost = self.character:GetBoosts()
			perksPanel:Clear()

			for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
				local attributeBoost = 0

				if boost[k] then
					for _, bValue in pairs(boost[k]) do
						attributeBoost = attributeBoost + bValue
					end
				end

				local bar = perksPanel:Add("ixAttributeBar")
				bar:Dock(TOP)
				bar:DockMargin(5, 5, 5, 0)

				local value = self.character:GetAttribute(k, 0)

				if attributeBoost then
					bar:SetValue(value - attributeBoost or 0)
				else
					bar:SetValue(value)
				end

				local maximum = v.maxValue or ix.config.Get("maxAttributes", 100)
				bar:SetMax(maximum)
				bar:SetReadOnly()
				bar:SetTall(tall * .045)
				--bar:SetText(Format("%s [%.1f/%.1f] (%.1f%%)", L(v.name), value, maximum, value / maximum * 100))
				bar:SetText(Format("%s (%.1f%%)", L(v.name), value / maximum * 100))

				if attributeBoost then
					bar:SetBoost(attributeBoost)
				end

				table.insert(self.characterAttrib, bar)
			end

			bUpdate = false
		end
	end

	nextCharButton.PaintOver = function(panel, width, height)
		surface.SetDrawColor(0, 0, 0, 135)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(Color(0, 0, 0, 129))
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	-- finalize setup
	self:SetActiveSubpanel("main", 0)
end

function PANEL:OnCharacterDeleted(character)
	if self.bActive and #ix.characters == 0 then
		self:SlideDown()
	end
end

function PANEL:Populate(ignoreID)
	self.character = ix.char.loaded[ix.characters[1]]
	self.characterid = 1
	self.carousel:SetActiveCharacter(self.character)
end

function PANEL:OnSlideUp()
	self.bActive = true
	self:Populate()
end

function PANEL:OnSlideDown()
	self.bActive = false
end

function PANEL:OnCharacterButtonSelected(panel)
	self.carousel:SetActiveCharacter(panel.character)
	self.character = panel.character
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintCharacterLoadBackground", self, width, height)

	surface.SetDrawColor(ix.config.Get("color"))
	surface.DrawRect(0, height * .05, width, 1)

	draw.DrawText(L"loadTitle", "ixSubTitleFont", width * .11, 0, ix.config.Get("color"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("ixCharMenuLoad", PANEL, "ixCharMenuPanel")