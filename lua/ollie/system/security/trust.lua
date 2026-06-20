local M = {}

-- check workspace path
function M.current_workspace()
    return vim.fn.getcwd()
end

function M.is_trusted(_)
    return true
end

return M
