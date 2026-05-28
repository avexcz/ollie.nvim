local M = {}
-- work on "If sufficient RAm then use qwen2.5-coder:3b/mid/high else use cloud AI " on health check of the system, also add a check to see if ollama server is running or not and if not then fallback to cloud AI (maybe gpt4all or something)
function M.get_cpu_usage()
        
    --[[
    1. get cpu info 
    2. check capacity (cores)
    3. verify good or not using if then do statement
    ]]
    local cpu = vim.uv.cpu_info()
    
    return {
    cores = #cpu,
    model = cpu[1].model,
    speed = cpu[1].speed,
    }
end


--[[
local function get_memory_usage()
1. get memory info
2. check capacity (RAM)
3. verify good or not using if then do statement

    


    return 65
end


function M.get_system_health()
    -- alocate both of function (get_cpu_usage and get_memory_usage) and display the result on vim notify once in a time and verify overall system health status- good, normal, need upgrade

    return {
        cpu_usage = get_cpu_usage(),
        memory_usage = get_memory_usage(),
    }
end
]]
            


return M
