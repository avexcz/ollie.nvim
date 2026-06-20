local M = {}

-- default policy 
local defaults = {
    allow_network = true,
    allow_providers = {
        ollama = true
    },
    max_prompt_chars = 120000,
}

local current = vim.deepcopy(defaults)

function M.setup(opts)
    current = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
    return vim.deepcopy(current)
end

function M.is_provider_allowed(provider)
    return current.allow_providers[provider] == true
end

function M.validate_prompt(prompt)
    if type(prompt) ~= "string" or vim.trim(prompt) == "" then
        return false, "Prompt is empty."
    end

    if #prompt > current.max_prompt_chars then
        return false, "Prompt exceeds max_prompt_chars."
    end

    return true
end

return M
