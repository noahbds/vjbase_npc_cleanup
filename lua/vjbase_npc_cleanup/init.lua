util.AddNetworkString("vjbase_npc_cleanup_update_config")
util.AddNetworkString("vjbase_npc_cleanup_request_config")
util.AddNetworkString("vjbase_npc_cleanup_send_config")
util.AddNetworkString("vjbase_npc_cleanup_notify")

Vjbase_npc_cleanup = Vjbase_npc_cleanup or {}

-- Function to save configuration to a file
function Vjbase_npc_cleanup.SaveConfig()
    if SERVER then
        -- Convert debug_mode to boolean before saving
        Vjbase_npc_cleanup.config.debug_mode = Vjbase_npc_cleanup.config.debug_mode or false
        file.Write("vjbase_npc_cleanup_config.txt", util.TableToJSON(Vjbase_npc_cleanup.config))
    end
end

-- Function to load configuration from a file
function Vjbase_npc_cleanup.LoadConfig()
    if SERVER then
        if file.Exists("vjbase_npc_cleanup_config.txt", "DATA") then
            local data = file.Read("vjbase_npc_cleanup_config.txt", "DATA")
            local config = util.JSONToTable(data)
            if config then
                Vjbase_npc_cleanup.config = Vjbase_npc_cleanup.config or
                    {}                                         -- Ensure Vjbase_npc_cleanup.config is initialized
                table.Merge(Vjbase_npc_cleanup.config, config) -- Merge the loaded configuration
            end
        end
    end
end

-- Load config when the addon is initialized
Vjbase_npc_cleanup.LoadConfig()

local function SetRagdollDebugMode(ragdoll, enable)
    if enable then
        ragdoll:SetColor(Color(255, 0, 0))
        ragdoll:SetRenderMode(RENDERMODE_TRANSCOLOR)
    else
        ragdoll:SetColor(Color(255, 255, 255))
        ragdoll:SetRenderMode(RENDERMODE_NORMAL)
    end
end

local function IsPlayerLookingAtRagdoll(player, ragdoll)
    local playerToRagdoll = ragdoll:GetPos() - player:GetShootPos()
    playerToRagdoll:Normalize()

    local dotProduct = player:GetAimVector():Dot(playerToRagdoll)
    return dotProduct > 0.5 -- Change this value to adjust the FOV
end

local function RemoveBodyIfNotSeen(ragdoll)
    if not IsValid(ragdoll) then return end

    local lastSeenTime = CurTime()

    timer.Create("vjbase_npc_cleanup_check_" .. ragdoll:EntIndex(), Vjbase_npc_cleanup.config.check_interval, 0,
        function()
            if not IsValid(ragdoll) then return end

            local seen = false
            for _, ply in ipairs(player.GetAll()) do
                if IsPlayerLookingAtRagdoll(ply, ragdoll) then
                    seen = true
                    lastSeenTime = CurTime()
                    break
                end
            end

            if not seen then
                local timeElapsed = CurTime() - lastSeenTime
                if timeElapsed >= Vjbase_npc_cleanup.config.body_removal_time then
                    ragdoll:Remove()
                    if Vjbase_npc_cleanup.config.debug_mode then
                        for _, ply in ipairs(player.GetAll()) do
                            ply:ChatPrint("Ragdoll " .. ragdoll:EntIndex() .. " a été supprimé.")
                        end
                    end
                    timer.Remove("vjbase_npc_cleanup_check_" .. ragdoll:EntIndex())
                end
            end
        end)
end

local function RemoveBloodEffects(ragdoll)
    if not IsValid(ragdoll) then return end

    -- Iterate through all decals on the ragdoll and remove blood effects
    local pos = ragdoll:GetPos()
    local radius = 200 -- Adjust the radius as needed
    local decals = ents.FindInSphere(pos, radius)
    for _, decal in ipairs(decals) do
        if decal:GetClass() == "decal" and decal:GetKeyValues().texture == "decals/blood" then
            decal:Remove()
        end
    end
end

hook.Add("CreateEntityRagdoll", "vjbase_npc_cleanup_CreateEntityRagdoll", function(npc, ragdoll)
    if npc.IsVJBaseSNPC and npc.IsVJBaseSNPC == true then
        -- Set debug mode for newly created ragdolls
        SetRagdollDebugMode(ragdoll, Vjbase_npc_cleanup.config.debug_mode)

        -- Remove blood effects associated with the ragdoll
        RemoveBloodEffects(ragdoll)

        timer.Simple(Vjbase_npc_cleanup.config.body_removal_time, function()
            RemoveBodyIfNotSeen(ragdoll)
        end)
    end
end)

net.Receive("vjbase_npc_cleanup_update_config", function(len, ply)
    if not ply:IsAdmin() then return end

    local newConfig = net.ReadTable()
    table.Merge(Vjbase_npc_cleanup.config, newConfig)
    Vjbase_npc_cleanup.SaveConfig() -- Save the updated config to a file

    -- Apply debug mode state to existing ragdolls when config is updated
    for _, ragdoll in ipairs(ents.FindByClass("prop_ragdoll")) do
        SetRagdollDebugMode(ragdoll, Vjbase_npc_cleanup.config.debug_mode)
    end
end)

net.Receive("vjbase_npc_cleanup_request_config", function(len, ply)
    if not ply:IsAdmin() then return end

    net.Start("vjbase_npc_cleanup_send_config")
    net.WriteTable(Vjbase_npc_cleanup.config)
    net.Send(ply)
end)
