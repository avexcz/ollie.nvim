local M = {}

local current_model = "avexcoder_3b:latest"
local current_provider = "ollama"

function M.get_state()
    return {
        provider = M.current_provider,
        model = M.current_model,
    }
end

function M.get_provider()
    return M.current_provider
end

function M.get_model()
    return M.current_model
end

function M.set_model(model)
    current_model = model
end

function M.set_provider(provider)
    current_provider = provider
end

return M