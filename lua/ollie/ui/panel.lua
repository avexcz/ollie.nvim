local M = {}

local renderer = require("ollie.ui.behaviour.renderer")

local state = {
    buf = nil,
    win = nil,
}

-- validation
local function is_valid()
    return state.buf
        and vim.api.nvim_buf_is_valid(state.buf)
        and state.win
        and vim.api.nvim_win_is_valid(state.win)
end

-- open panel
function M.open(position)
    position = position or "right"

    -- create buffer
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)

        vim.bo[state.buf].bufhidden = "wipe"
        vim.bo[state.buf].swapfile = false
        vim.bo[state.buf].filetype = "markdown"
        vim.bo[state.buf].buflisted = false
    end

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "", "" })

    -- close old window
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    -- layout
    local width = math.floor(vim.o.columns * 0.30)
    local height = vim.o.lines - 2
    local col = position == "left" and 0 or (vim.o.columns - width)
    local row = 1

    -- full border
    local border = {
        "┌", "─", "┐", "│",
        "┘", "─", "└", "│",
    }

    local win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = border,
        title = " Ollie AI",
        title_pos = "center",
        noautocmd = true,
    })

    -- window options
    local wo = vim.wo[win]
    wo.winfixwidth = true
    wo.winfixheight = true
    wo.number = false
    wo.relativenumber = false
    wo.signcolumn = "no"
    wo.cursorline = false
    wo.wrap = true
    wo.list = false
    wo.spell = false
    wo.foldenable = false
    wo.fillchars = "eob: "

    renderer.format(win)

    -- optional header
    vim.api.nvim_buf_set_lines(state.buf, 0, 1, false, {
        " Ollie Panel ",
    })

    vim.api.nvim_buf_add_highlight(state.buf, -1, "Title", 0, 0, -1)

    -- close keybind
    vim.api.nvim_buf_set_keymap(
        state.buf,
        "n",
        "q",
        "",
        {
            noremap = true,
            silent = true,
            callback = function() M.close() end,
        }
    )

    state.win = win
    return state.buf
end

-- resize
function M.resize()
    local win = state.win
    if not win or not vim.api.nvim_win_is_valid(win) then
        return
    end

    local width = math.floor(vim.o.columns * 0.30)
    local height = vim.o.lines - 2

    vim.api.nvim_win_set_config(win, {
        relative = "editor",
        width = width,
        height = height,
        row = 1,
        col = vim.o.columns - width,
    })
end


function M.append(text)
    if not is_valid() then return end

    vim.bo[state.buf].modifiable = true

    -- get current last line
    local line_count = vim.api.nvim_buf_line_count(state.buf)
    local last_line = vim.api.nvim_buf_get_lines(state.buf, line_count - 1, line_count, false)[1] or ""

    -- split incoming chunk by newlines
    local chunks = vim.split(text, "\n", { plain = true })

    -- append first chunk to existing last line
    chunks[1] = last_line .. chunks[1]

    -- write back
    vim.api.nvim_buf_set_lines(state.buf, line_count - 1, line_count, false, chunks)

    -- scroll to bottom
    if vim.api.nvim_win_is_valid(state.win) then
        local new_line_count = vim.api.nvim_buf_line_count(state.buf)
        vim.api.nvim_win_set_cursor(state.win, { new_line_count, 0 })
    end
end


function M.finish()
    if not is_valid() then return end
    vim.bo[state.buf].modifiable = false
end

function M.close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    state.buf = nil
end

function M.get_win() return state.win end
function M.get_buf() return state.buf end

return M