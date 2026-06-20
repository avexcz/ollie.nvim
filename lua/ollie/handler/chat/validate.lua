local M = {}

-- query validation
function M.query(query)

    if type(query) ~= "string" then
        return false, "Query must be a string."
    end

    if vim.trim(query) == "" then
        return false, "Query cannot be empty."
    end

    return true
end


return M