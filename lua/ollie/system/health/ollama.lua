local M = {}

local ollama = require("ollie.providers.ollama.model")

-- checks ollama server availability and retrieves installed model list.
-- uses a short timeout curl request to avoid blocking.
function M.checkhealth()
    local result = vim.system(
        { "curl", "-sS", "--max-time", "2", ollama.config.host .. "/api/tags" },
        { text = true }
    ):wait()

    -- network/service failure case
    if result.code ~= 0 then
        return {
            ok = false,
            status = "unavailable",
            models = {},
            error = vim.trim(result.stderr or ""),
        }
    end

    -- safely decode json response from Ollama API
    local ok, decoded = pcall(vim.json.decode, result.stdout or "")
    local models = {}

    -- extract model names if response format is valid
    if ok and type(decoded) == "table" then
        for _, model in ipairs(decoded.models or {}) do
            if model.name then
                table.insert(models, model.name)
            end
        end
    end

    table.sort(models)

    return {
        ok = true,
        status = "available",
        models = models,
    }
end

-- Suggests an appropriate local model based on system memory.
function M.modelsuggest()
    local hardware = require("ollie.system.health.hardware").get_system_health()
    local memory_gb = hardware.memory.total / 1024 / 1024 / 1024

    if memory_gb >= 16 then
        return "qwen2.5-coder:3b"
    end

    if memory_gb >= 8 then
        return "qwen2.5-coder:1.5b"
    end

    return "Use a cloud provider or a smaller local model."
end

return M