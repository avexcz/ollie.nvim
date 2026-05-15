local hardware = require("ollie.system.health.hardware")

local M = {}

function M.get_health_status()
    local health = hardware.get_system_health()

    if not health then
        return {
            cpu_usage = 0,
            memory_usage = 0,
            status = "unknown",
        }
    end

    return {
        cpu_usage = health.cpu_usage or 0,
        memory_usage = health.memory_usage or 0,
        status = "ok",
    }
end

return M