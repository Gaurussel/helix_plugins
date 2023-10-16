local buttonPadding = ScreenScale(14) * 0.5
-- base menu button
DEFINE_BASECLASS("DButton")
local PANEL = {}
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha")

function PANEL:Init()
    self:SetFont("ixBankFont")
    self:SetTextColor(color_black)
    self:SetPaintBackground(false)
    self:SetContentAlignment(4)
    self:SetTextInset(buttonPadding, 0)

    -- left, top, right, bottom
    self.padding = {16, 6, 16, 6}

    self.backgroundColor = Color(0, 0, 0)
    self.backgroundAlpha = 128
    self.currentBackgroundAlpha = 0
end

function PANEL:GetPadding()
    return self.padding
end

function PANEL:SetPadding(left, top, right, bottom)
    self.padding = {left or self.padding[1], top or self.padding[2], right or self.padding[3], bottom or self.padding[4]}
end

function PANEL:SetText(text, noTranslation)
    BaseClass.SetText(self, noTranslation and text:utf8upper() or L(text):utf8upper())
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)
    local width, height = self:GetSize()
    self:SetSize(width + self.padding[1] + self.padding[3], height + self.padding[2] + self.padding[4])
end

function PANEL:PaintBackground(width, height)
    -- surface.SetDrawColor(color_black)
    -- surface.DrawOutlinedRect(0, 0, width, height, 5)
end

function PANEL:Paint(width, height)
    self:PaintBackground(width, height)
    BaseClass.Paint(self, width, height)
end

function PANEL:SetTextColorInternal(color)
    BaseClass.SetTextColor(self, color)
    self:SetFGColor(color)
end

function PANEL:SetTextColor(color)
    self:SetTextColorInternal(color)
    self.color = color
end

function PANEL:SetDisabled(bValue)
    local color = self.color

    if bValue then
        self:SetTextColorInternal(Color(math.max(color.r - 60, 0), math.max(color.g - 60, 0), math.max(color.b - 60, 0)))
    else
        self:SetTextColorInternal(color)
    end

    BaseClass.SetDisabled(self, bValue)
end

function PANEL:OnCursorEntered()
    if self:GetDisabled() then return end
    local color = self:GetTextColor()
    self:SetTextColorInternal(Color(math.max(color.r - 25, 0), math.max(color.g - 25, 0), math.max(color.b - 25, 0)))

    self:CreateAnimation(0.15, {
        target = {
            currentBackgroundAlpha = self.backgroundAlpha
        }
    })

    LocalPlayer():EmitSound("Helix.Rollover")
end

function PANEL:OnCursorExited()
    if self:GetDisabled() then return end

    if self.color then
        self:SetTextColor(self.color)
    else
        self:SetTextColor(color_white)
    end

    self:CreateAnimation(0.15, {
        target = {
            currentBackgroundAlpha = 0
        }
    })
end

function PANEL:OnMousePressed(code)
    if self:GetDisabled() then return end

    if self.color then
        self:SetTextColor(self.color)
    else
        self:SetTextColor(ix.config.Get("color"))
    end

    LocalPlayer():EmitSound("Helix.Press")

    if code == MOUSE_LEFT and self.DoClick then
        self:DoClick(self)
    elseif code == MOUSE_RIGHT and self.DoRightClick then
        self:DoRightClick(self)
    end
end

function PANEL:OnMouseReleased(key)
    if self:GetDisabled() then return end

    if self.color then
        self:SetTextColor(self.color)
    else
        self:SetTextColor(color_white)
    end
end

vgui.Register("ixBankButton", PANEL, "DButton")