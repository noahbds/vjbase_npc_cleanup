concommand.Add("vjbase_npc_cleanup_openmenu", function(ply)
    if not ply:IsAdmin() then return end

    -- Request the current config from the server
    net.Start("vjbase_npc_cleanup_request_config")
    net.SendToServer()

    -- Create the frame after receiving the config from the server
    net.Receive("vjbase_npc_cleanup_send_config", function()
        local config = net.ReadTable()

        local frame = vgui.Create("DFrame")
        frame:SetTitle("VJ Base NPC Cleanup Configuration")
        frame:SetSize(300, 180)
        frame:Center()
        frame:MakePopup()

        local bodyRemovalTime = vgui.Create("DNumSlider", frame)
        bodyRemovalTime:SetPos(10, 30)
        bodyRemovalTime:SetSize(280, 30)
        bodyRemovalTime:SetText("Body Removal Time")
        bodyRemovalTime:SetMin(1)
        bodyRemovalTime:SetMax(60)
        bodyRemovalTime:SetDecimals(0)
        bodyRemovalTime:SetValue(config.body_removal_time)

        local checkInterval = vgui.Create("DNumSlider", frame)
        checkInterval:SetPos(10, 70)
        checkInterval:SetSize(280, 30)
        checkInterval:SetText("Check Interval")
        checkInterval:SetMin(0.1)
        checkInterval:SetMax(5)
        checkInterval:SetDecimals(1)
        checkInterval:SetValue(config.check_interval)

        local debugMode = vgui.Create("DCheckBoxLabel", frame)
        debugMode:SetPos(10, 110)
        debugMode:SetSize(280, 30)
        debugMode:SetText("Debug Mode")
        debugMode:SetValue(config.debug_mode)
        debugMode:SizeToContents()

        local saveButton = vgui.Create("DButton", frame)
        saveButton:SetPos(10, 140)
        saveButton:SetSize(280, 30)
        saveButton:SetText("Save")
        saveButton.DoClick = function()
            net.Start("vjbase_npc_cleanup_update_config")
            net.WriteTable({
                body_removal_time = bodyRemovalTime:GetValue(),
                check_interval = checkInterval:GetValue(),
                debug_mode = debugMode:GetValue()
            })
            net.SendToServer()
            frame:Close()
        end
    end)
end)
