local M = {}

--load security modules
local policies = require("ollie.system.security.policies")
local permission = require("ollie.system.security.permission")
local trust = require("ollie.system.security.trust")

function M.setup(opts)
    policies.setup(opts)
end

M.policies = policies
M.permission = permission
M.trust = trust

return M
