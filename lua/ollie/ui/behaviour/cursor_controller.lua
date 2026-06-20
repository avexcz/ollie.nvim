local M = {}

function M.set_position(win, line)
    -- cursor behaviour
    if not win or not vim.api.nvim_win_is_valid(win) then return end

    local buf = vim.api.nvim_win_get_buf(win) -- get buffer
    local line_count = vim.api.nvim_buf_line_count(buf) -- get buffer's total loc

    if line < 1 then line = 1 end
    if line > line_count then line = line_count end
    
    vim.api.nvim_win_set_cursor(win, { line, 0 }) -- set the cursor position to the beginning of the specified line (line number, column 0)
end

function M.reset(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

function M.to_bottom(win)
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local last = vim.api.nvim_buf_line_count(buf)

    vim.api.nvim_win_set_cursor(win, { last, 0 })
end
return M