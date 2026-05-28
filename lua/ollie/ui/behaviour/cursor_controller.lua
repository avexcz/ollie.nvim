local M = {}

function M.cursor(win, line)
    -- cursor behaviour
    if not line then return end
    vim.api.nvim_win_set_cursor(win, { line, 0 }) -- set the cursor position to the beginning of the specified line (line number, column 0)


end
return M