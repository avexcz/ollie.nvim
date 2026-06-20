local M = {}

local policies = require("ollie.system.security.policies")
local trust = require("ollie.system.security.trust")

function M.authorize_request(request)
    request = request or {}

    if not trust.is_trusted(trust.current_workspace()) then
        return false, "Workspace is not trusted."
    end

    if not policies.is_provider_allowed(request.provider) then
        return false, "Provider is not allowed: " .. tostring(request.provider)
    end

    local ok, err = policies.validate_prompt(request.prompt)
    if not ok then
        return false, err
    end

    return true
end

return M
