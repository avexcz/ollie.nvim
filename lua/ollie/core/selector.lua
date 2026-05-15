local M = {}

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
    M.current_model = model
end

function M.set_provider(provider)
    M.current_provider = provider
end

return M