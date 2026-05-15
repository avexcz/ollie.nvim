local M = {}
--test and detect power of ram and cpu usage.

local function get_cpu_usage()
    -- Placeholder for CPU usage retrieval logic




    return 42
end


local function get_memory_usage()
    -- Placeholder for memory usage retrieval logic






    return 65
end


function M.get_system_health()
    return {
        cpu_usage = get_cpu_usage(),
        memory_usage = get_memory_usage(),
    }
end

            




return M