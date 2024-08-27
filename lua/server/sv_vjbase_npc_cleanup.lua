util.AddNetworkString("VjbaseNpcCleanup_Config")
util.AddNetworkString("VjbaseNpcCleanup_ConfigUpdate")
util.AddNetworkString("VjbaseNpcCleanup_DebugMode")

local configFileName = "vjbase_npc_cleanup_config.txt"

-- Default Configuration
local defaultConfig = {
    fov_threshold = 0.5,
    check_interval = 1,
    initial_delay = 5
}

local config = table.Copy(defaultConfig)

-- Function to check if the player is an admin
local function IsAdmin(ply)
    return ply:IsAdmin()
end

-- Function to save the config to file
local function SaveConfig()
    file.Write(configFileName, util.TableToJSON(config, true))
end

-- Function to load the config from file
local function LoadConfig()
    if file.Exists(configFileName, "DATA") then
        local json = file.Read(configFileName, "DATA")
        config = util.JSONToTable(json) or table.Copy(defaultConfig)
    else
        SaveConfig()
    end
end

-- Load the config at server startup
LoadConfig()

-- Function to send the config to a specific player
local function SendConfig(ply)
    net.Start("VjbaseNpcCleanup_Config")
    net.WriteTable(config)
    net.Send(ply)
end

-- Broadcast the config to all players
local function BroadcastConfig()
    net.Start("VjbaseNpcCleanup_Config")
    net.WriteTable(config)
    net.Broadcast()
end

-- Receive config updates from clients (admin only)
net.Receive("VjbaseNpcCleanup_ConfigUpdate", function(len, ply)
    if not IsAdmin(ply) then return end

    local newConfig = net.ReadTable()
    if istable(newConfig) then
        config = newConfig
        SaveConfig()
        BroadcastConfig()
    end
end)

-- Send the config to players when they spawn
hook.Add("PlayerInitialSpawn", "VjbaseNpcCleanup_PlayerInitialSpawn", function(ply)
    SendConfig(ply)
end)

-- Table to store all ragdolls
local ragdolls = {}

-- Function to check if a player is looking at the ragdoll
local function IsPlayerLookingAtRagdoll(player, ragdoll, fov_threshold)
    local playerToRagdoll = ragdoll:GetPos() - player:GetShootPos()
    playerToRagdoll:Normalize()

    local dotProduct = player:GetAimVector():Dot(playerToRagdoll)
    return dotProduct > fov_threshold
end

-- Function to remove the ragdoll if no player is looking at it
local function RemoveBodyIfNotSeen(ragdoll)
    if not IsValid(ragdoll) then return end

    local isSeen = false
    local players = player.GetAll()
    for i = 1, #players do
        if IsPlayerLookingAtRagdoll(players[i], ragdoll, config.fov_threshold) then
            isSeen = true
            break
        end
    end

    if not isSeen then
        ragdoll:Remove()
        ragdolls[ragdoll] = nil
    else
        ragdoll.nextCheck = CurTime() + config.check_interval
    end
end

-- Function to periodically check the ragdoll
local function PeriodicCheck()
    for ragdoll in pairs(ragdolls) do
        if not IsValid(ragdoll) then
            ragdolls[ragdoll] = nil
        elseif CurTime() >= (ragdoll.nextCheck or 0) then
            RemoveBodyIfNotSeen(ragdoll)
        end
    end
end

-- Hook to detect when an entity is created
hook.Add("OnEntityCreated", "VjbaseNpcCleanup_OnEntityCreated", function(ent)
    timer.Simple(0.1, function()
        if not IsValid(ent) then return end
        if ent:GetClass() == "prop_ragdoll" then
            ent.nextCheck = CurTime() + config.initial_delay
            ragdolls[ent] = true
        end
    end)
end)

-- Add a single "Think" hook to check all ragdolls
hook.Add("Think", "VjbaseNpcCleanup_Think", PeriodicCheck)

-- Note: Implement this function as needed for debugging purposes
net.Receive("VjbaseNpcCleanup_DebugMode", function(len, ply)
    local enable = net.ReadBool()
    local ragdoll = net.ReadEntity()

    if not IsValid(ragdoll) then return end

    if enable then
        ragdoll:SetColor(Color(255, 0, 0, 255))

        hook.Add("PostDrawOpaqueRenderables", ragdoll, function()
            local pos = ragdoll:GetPos()
            local players = player.GetAll()
            for _, player in ipairs(players) do
                render.DrawLine(player:GetShootPos(), pos, Color(0, 255, 0), true)
            end
        end)
    else
        ragdoll:SetColor(Color(255, 255, 255, 255))
        hook.Remove("PostDrawOpaqueRenderables", ragdoll)
    end
end)

-- Cleanup function when the entity is removed
hook.Add("EntityRemoved", "VjbaseNpcCleanup_EntityRemoved", function(ent)
    if ent:GetClass() == "prop_ragdoll" then
        hook.Remove("Think", ent)
    end
end)
