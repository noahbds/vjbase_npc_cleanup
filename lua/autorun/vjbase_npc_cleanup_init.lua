-- Load server-side script
if SERVER then
    include("server/sv_vjbase_npc_cleanup.lua")
end

-- Load client-side script
if CLIENT then
    include("client/cl_vjbase_npc_cleanup.lua")
end
