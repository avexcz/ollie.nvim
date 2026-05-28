local M = {}

-- internal safe append helper
local function is_valid(buf, win)
    return buf
        and vim.api.nvim_buf_is_valid(buf)
        and win
        and vim.api.nvim_win_is_valid(win)
end

-- core streaming append logic
function M.append(buf, win, text)
    if not is_valid(buf, win) then
        return
    end

    if not text or text == "" then
        return
    end

    vim.bo[buf].modifiable = true

    -- get last line
    local line_count = vim.api.nvim_buf_line_count(buf)
    local last_line = vim.api.nvim_buf_get_lines(
        buf,
        line_count - 1,
        line_count,
        false
    )[1] or ""

    -- split incoming stream
    local parts = vim.split(text, "\n", { plain = true })

    -- merge with previous incomplete line
    parts[1] = last_line .. parts[1]

    -- write updated content
    vim.api.nvim_buf_set_lines(
        buf,
        line_count - 1,
        line_count,
        false,
        parts
    )

    -- auto-scroll to bottom
    vim.api.nvim_win_set_cursor(win, {
        vim.api.nvim_buf_line_count(buf),
        0
    })
end

-- finalize stream (lock editing + reset cursor)
function M.finish(buf, win)
    if not is_valid(buf, win) then
        return
    end

    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

return M