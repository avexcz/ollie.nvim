local M = {}

--------------------------
-- default configuration
--------------------------

local defaults = {

    -- provider and model settings
    default_provider = "ollama",
    default_model = "avexcoder_3b:latest",

    -- chat settings
    streaming = true,
    include_context = true,


    -- ui settings
    render_mode = "chat",
    border = "rounded",


    -- context settings
    max_context_lines = 300,
}

-- active config
M.values = vim.deepcopy(defaults) -- start with defaults


-- setup
function M.setup(user_config)

    user_config = user_config or {}
    M.values = vim.tbl_deep_extend(
        "force",
        defaults,
        user_config
    )

end


-- get config value
function M.get(key)
    return M.values[key]
end


-- set config value
function M.set(key, value)
    M.values[key] = value
end

return M
