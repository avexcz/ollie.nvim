local M = {}

-----------------------
-- query validation
-----------------------
function M.query(query)

    if type(query) ~= "string" then
        return false, "Query must be a string."
    end

    if vim.trim(query) == "" then
        return false, "Query cannot be empty."
    end

    return true
end

-----------------------
-- provider validation
-----------------------
function M.provider(provider)

    if type(provider) ~= "string" then
        return false, "Provider must be a string."
    end

    if vim.trim(provider) == "" then
        return false, "Provider cannot be empty."
    end

    return true
end

---------------------
-- model validation
---------------------
function M.model(model)

    if type(model) ~= "string" then
        return false, "Model must be a string."
    end

    if vim.trim(model) == "" then
        return false, "Model cannot be empty."
    end

    return true
end

return M