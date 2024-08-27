-- Shared interface or helper functions can be added here

-- Function to send a notification to all players
function Vjbase_npc_cleanup.NotifyAll(message, messageType)
    net.Start("vjbase_npc_cleanup_notify")
    net.WriteString(message)
    net.WriteUInt(messageType or NOTIFY_GENERIC, 3)
    net.Broadcast()
end

-- Function to send a notification to a single player
function Vjbase_npc_cleanup.NotifyPlayer(ply, message, messageType)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    net.Start("vjbase_npc_cleanup_notify")
    net.WriteString(message)
    net.WriteUInt(messageType or NOTIFY_GENERIC, 3)
    net.Send(ply)
end

-- Utility function to merge tables (deep copy)
function table.DeepMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            table.DeepMerge(t1[k], v)
        else
            t1[k] = v
        end
    end
end

if SERVER then
    util.AddNetworkString("vjbase_npc_cleanup_notify")
else
    net.Receive("vjbase_npc_cleanup_notify", function()
        local message = net.ReadString()
        local messageType = net.ReadUInt(3)
        notification.AddLegacy(message, messageType, 5)
        surface.PlaySound("buttons/button15.wav")
    end)
end
