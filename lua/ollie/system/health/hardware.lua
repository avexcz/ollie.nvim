local M = {}

-- Get CPU hardware information (cores, model, and base clock speed)
function M.get_cpu_usage()
    local cpu = vim.uv.cpu_info()
    
    return {
        cores = #cpu,
        model = cpu[1] and cpu[1].model or "unknown",
        speed = cpu[1] and cpu[1].speed or 0, -- clock speed
    }
end

-- get memory hardware information (total memory, remaining memory and used memory with percentage)
function M.get_memory_usage()
    local total = vim.uv.get_total_memory()
    local free = vim.uv.get_free_memory()
    local used = total - free

    return {
        total = total,
        free = free,
        used = used,
        used_percent = total > 0 and math.floor((used / total) * 100) or 0,
    }
end

-- get disk hardware information (used, size, availability, and percentage)
function M.get_disk()
    local handle = io.popen("df -h /")
    if not handle then
        return nil
    end

    local result = handle:read("*a")
    handle:close()

    local used, size, avail, percent = result:match("/%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)") -- parser

    return {
        used = used,
        size = size,
        available = avail,
        usage = percent,
    }
end

-- load system hardware information completely with the combination of cpu, and memory
function M.get_system_health()
    local cpu = M.get_cpu_usage()
    local memory = M.get_memory_usage()

    local memory_gb = memory.total / 1024 / 1024 / 1024

    local status = "ok"

    if cpu.cores < 4 or memory_gb < 4 then
        status = "limited"
    elseif cpu.cores >= 8 and memory_gb >= 16 then
        status = "good"
    end

    return {
        cpu = cpu,
        memory = memory,
        status = status,
    }
end

return M
