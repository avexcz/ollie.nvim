local M = {}

local hardware = require("ollie.system.health.hardware")
local ollama = require("ollie.system.health.ollama")
local models = require("ollie.system.health.models")

-- initialize the health status
function M.get_health_status()
    return {
        hardware = hardware.get_system_health(),
        ollama = ollama.checkhealth(),
        recommendation = models.recommend(),
    }
end

function M.check()
    vim.health.start("Ollie System")


    local hw = hardware.get_system_health()
    local disk = hardware.get_disk()

    if hw then
        vim.health.ok("Hardware information detected")
    else
        vim.health.error("Unable to read hardware information")
    end

    if hw and hw.memory then
        vim.health.info(
            string.format(
                "Memory usage: %.1f%%",
                hw.memory.used_percent or 0
            )
        )

        if (hw.memory.used_percent or 0) > 85 then
            vim.health.warn("High memory usage")
        end
    end

    if disk and disk.usage then
        vim.health.info("Disk usage: " .. tostring(disk.usage))

        local percent

        if type(disk.usage) == "number" then
            percent = disk.usage
        elseif type(disk.usage) == "string" then
            percent = tonumber(disk.usage:match("(%d+)"))
        end

        if percent and percent > 85 then
            vim.health.warn("High disk usage")
        end
    else
        vim.health.warn("Unable to determine disk usage")
    end

    local ollama_ok = ollama.checkhealth()

    if ollama_ok then
        vim.health.ok("Ollama is available")
    else
        vim.health.warn("Ollama is unavailable")
    end

    local recommendation = models.recommend()

    if recommendation and recommendation.model then
        vim.health.info(
            string.format(
                "Recommended model: %s (%s)",
                recommendation.model,
                recommendation.provider
            )
        )
    end
end

return M