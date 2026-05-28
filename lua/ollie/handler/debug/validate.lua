local M = {}

function M.fix(query, selected_code)
    if type(query) ~= "string" or vim.trim(query) == ""
    then
        return false,
        "Empty instruction."
    end

    if type(selected_code) ~= "string" or vim.trim(selected_code) == ""
    then
        return false, 
        "No selected code found."
    end

    return true
end

return M