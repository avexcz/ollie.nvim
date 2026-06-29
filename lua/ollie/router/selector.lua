local M = {}

local providers = require("ollie.providers")
local config = require("ollie.core.config")

function M.select()
    return {
        provider = config.get("default_provider"),
        model = config.get("default_model"),
    }
end

-- get the current state
function M.get_state()
    return {
        provider = config.get("default_provider"),
        model = config.get("default_model"),
    }
end

-- get the provider and model for a given task type
function M.get_provider()
    return config.get("default_provider")
end

function M.get_model()
    return config.get("default_model")
end

-- set the provider and model
function M.set_model(model)
    if type(model) ~= "string" or vim.trim(model) == "" then
        return vim.notify("Model not found or install model.", vim.log.levels.ERROR, { title = "Ollie Router" })
    end

    config.set("default_model", model)
    return true
end

function M.set_provider(provider)
    if type(provider) ~= "string" or vim.trim(provider) == "" then
        return vim.notify("Provider not found.", vim.log.levels.ERROR, { title = "Ollie Router" })
    end

    if not providers.get(provider) then
        return false
    end

    config.set("default_provider", provider)
    return true
end

function M.list_providers()
    return providers.names()
end

function M.list_models(provider)
    return providers.models(provider or config.get("default_provider"))
end

return M
