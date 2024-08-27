if SERVER then
    include("vjbase_npc_cleanup/init.lua")
else
    include("vjbase_npc_cleanup/cl_init.lua")
end

include("vjbase_npc_cleanup/sh_config.lua")
include("vjbase_npc_cleanup/sh_interface.lua")
