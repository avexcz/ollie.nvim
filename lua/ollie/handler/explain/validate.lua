--explain workflow
local M = {}

-- user explain validation
function M.explain(query, selected_code)

    if type(query) ~= "string" then
        return false,
        "Query must be a string."
    end

    if vim.trim(query) == "" then
        return false, 
        "Query cannot be empty."
    end

    if type(selected_code) ~= "string" then
        return false, 
        "Selected code must be a string."
    end

    if vim.trim(selected_code) == "" then
        return false,
        "No code selected."
    end

    return true
end

return M