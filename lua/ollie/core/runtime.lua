local M = {}

local config = require("ollie.core.config")
local selector = require("ollie.core.selector")

-- get the provider and model for a given task type
function M.provider(opts)
    opts = opts or {}
    return opts.provider or selector.get_provider() or config.get("default_provider")
end

function M.model(opts)
    opts = opts or {}
    return opts.model or selector.get_model() or config.get("default_model")
end

function M.streaming(opts)
    opts = opts or {}
    if opts.stream ~= nil then
        return opts.stream
    end

    return config.get("streaming")
end

return M
