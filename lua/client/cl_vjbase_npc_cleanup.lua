local config = {}
local debugMode = false

-- Receive the config from the server
net.Receive("VjbaseNpcCleanup_Config", function()
    config = net.ReadTable()
    PrintTable(config) -- For debugging
end)

-- Function to open the config menu
function OpenConfigMenu()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("VJ Base NPC Cleanup Config")
    frame:SetSize(300, 250)
    frame:Center()
    frame:MakePopup()

    ---@class DCheckBoxLabel
    local debugCheckbox = vgui.Create("DCheckBoxLabel", frame)
    debugCheckbox:SetText("Debug Mode")
    debugCheckbox:SetValue(debugMode)
    debugCheckbox:Dock(TOP)
    debugCheckbox.OnChange = function(self, val)
        debugMode = val
        net.Start("VjbaseNpcCleanup_DebugMode")
        net.WriteBool(debugMode)
        net.SendToServer()
    end

    ---@class DNumSlider
    local fovSlider = vgui.Create("DNumSlider", frame)
    fovSlider:SetText("FOV Threshold")
    fovSlider:SetMin(0)
    fovSlider:SetMax(1)
    fovSlider:SetDecimals(2)
    fovSlider:SetValue(config.fov_threshold)
    fovSlider:Dock(TOP)

    ---@class DNumSlider
    local intervalSlider = vgui.Create("DNumSlider", frame)
    intervalSlider:SetText("Check Interval (seconds)")
    intervalSlider:SetMin(0.1)
    intervalSlider:SetMax(10)
    intervalSlider:SetDecimals(1)
    intervalSlider:SetValue(config.check_interval)
    intervalSlider:Dock(TOP)

    ---@class DNumSlider
    local delaySlider = vgui.Create("DNumSlider", frame)
    delaySlider:SetText("Initial Delay (seconds)")
    delaySlider:SetMin(0)
    delaySlider:SetMax(60)
    delaySlider:SetDecimals(1)
    delaySlider:SetValue(config.initial_delay)
    delaySlider:Dock(TOP)

    ---@class DButton
    local applyButton = vgui.Create("DButton", frame)
    applyButton:SetText("Apply")
    applyButton:Dock(BOTTOM)
    applyButton.DoClick = function()
        config.fov_threshold = fovSlider:GetValue()
        config.check_interval = intervalSlider:GetValue()
        config.initial_delay = delaySlider:GetValue()

        net.Start("VjbaseNpcCleanup_ConfigUpdate")
        net.WriteTable(config)
        net.SendToServer()

        frame:Close()
    end
end

-- Open the config menu via console command (for admins only)
concommand.Add("vjbase_open_config", function(ply)
    if not ply:IsAdmin() then return end
    OpenConfigMenu()
end)
