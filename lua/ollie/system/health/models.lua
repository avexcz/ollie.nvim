local M = {}

local providers = require("ollie.providers")
local ollama_health = require("ollie.system.health.ollama")

function M.available(provider)
    return providers.models(provider)
end

function M.recommend()
    local model = ollama_health.modelsuggest()

    if not model then
        return nil
    end

    return {
        provider = "ollama",
        model = model,
    }
end

return M
