net.Receive("GIVERS.Edit", function()
    local ent = net.ReadEntity()
    local name = net.ReadString()
    local item = net.ReadString()

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * .3, ScrH() * .3)
    frame:Center()
    frame:SetTitle("Edit this")
    frame:MakePopup()

    local namerow = frame:Add("ixSettingsRowString")
    namerow:SetText("Name:")
    namerow:Dock(TOP)
    namerow:SetValue(name)

    local itemrow = frame:Add("ixSettingsRowString")
    itemrow:SetText("Item uniqueid:")
    itemrow:Dock(TOP)
    itemrow:SetValue(item)

    local modelrow = frame:Add("ixSettingsRowString")
    modelrow:SetText("Item model:")
    modelrow:Dock(TOP)
    modelrow:SetValue(ent:GetModel())

    local sendbutton = frame:Add("ixMenuButton")
    sendbutton:SetText("Save")
    sendbutton:SetFont("ixMenuButtonFont")
    sendbutton:SizeToContents()
    sendbutton:Dock(BOTTOM)
    sendbutton.DoClick = function()
        local nametext = namerow:GetValue()
        local itemtext = itemrow:GetValue()
        local modeltext = modelrow:GetValue()
        if nametext == "" or itemtext == "" or modeltext == "" then
            return
        end

        net.Start("GIVERS.Edit")
            net.WriteString(nametext)
            net.WriteString(itemtext)
            net.WriteString(modeltext)
            net.WriteEntity(ent)
        net.SendToServer()

        frame:Remove()
    end
end)