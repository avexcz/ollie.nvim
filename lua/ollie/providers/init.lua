local M = {}

M.providers = {
    ollama = require("ollie.providers.ollama.model")
}

function M.get(name)
    local provider = M.providers[name]

    if not provider then
        vim.notify(
            "Provider not found: " .. name,
            vim.log.levels.ERROR,
            { title = "Ollie" }
        )

        return nil
    end

    return provider
end

function M.names()
    local names = {}

    for name, _ in pairs(M.providers) do
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

function M.models(name)
    if name then
        local provider = M.get(name)
        if not provider then
            return {}
        end

        if type(provider.models) == "function" then
            return provider.models()
        end

        return vim.deepcopy(provider.models or {})
    end

    local result = {}

    for provider_name, provider in pairs(M.providers) do
        local models = type(provider.models) == "function"
            and provider.models()
            or provider.models

        for _, model in ipairs(models or {}) do
            table.insert(result, provider_name .. ":" .. model)
        end
    end

    table.sort(result)
    return result
end

return M
