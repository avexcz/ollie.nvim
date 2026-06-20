local M = {}

local health = require("ollie.system.health")

local function bytes_to_gb(bytes)
    return string.format("%.1f GB", bytes / 1024 / 1024 / 1024)
end

local function create_health_command()
    vim.api.nvim_create_user_command("OllieHealth", function()
        local status = health.get_health_status()
        local hw = status.hardware
        local mem = hw.memory
        local cpu = hw.cpu

        local lines = {
            "Hardware: " .. hw.status,
            "CPU: " .. tostring(cpu.cores) .. " cores, " .. tostring(cpu.model),
            "Memory: " .. bytes_to_gb(mem.used) .. " / " .. bytes_to_gb(mem.total)
                .. " (" .. tostring(mem.used_percent) .. "%)",
            "Ollama: " .. status.ollama.status,
            "Recommended: " .. status.recommendation.provider .. " / " .. status.recommendation.model,
        }

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Ollie Health" })
    end, {})
end

function M.setup()
    create_health_command()
end

return M
