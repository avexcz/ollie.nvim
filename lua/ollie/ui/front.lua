local M = {}

--renderer engine for formatting and stream engine
local renderer = require("ollie.ui.behaviour.renderer")

-- track state
local state = {
    buf = nil,
    win = nil,
}

-- create function
function M.open()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {""})
        vim.bo[state.buf].bufhidden = "wipe" --prevents memory leak
        vim.bo[state.buf].swapfile = false -- no swaping
        vim.bo[state.buf].filetype = "markdown" --file type
        vim.bo[state.buf].buflisted = false -- hide from buffer list
    end


    vim.bo[state.buf].modifiable = true -- allows modifying
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { "" })


    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    local width = math.floor(vim.o.columns * 0.7)
    local height = math.floor(vim.o.lines * 0.7)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

   local win = vim.api.nvim_open_win(state.buf, true, {

        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,

        style = "minimal",
        border = "rounded",

        title = "Ollie AI",
        title_pos = "center",

        noautocmd = true,
    })

    renderer.format(win)

    vim.api.nvim_buf_set_keymap(
        state.buf,
        "n",
        "q",
        "<cmd>bd!<CR>",
        { noremap = true, silent = true }
    )

    state.win = win

    return state.buf
end

-- append function
function M.append(chunk)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end

    vim.bo[state.buf].modifiable = true

    local line_count = vim.api.nvim_buf_line_count(state.buf)
    -- get the current last line
    local last_line = vim.api.nvim_buf_get_lines(
        state.buf, line_count - 1, line_count, false
    )[1] or ""

    -- split chunk by newlines
    local parts = vim.split(chunk, "\n", { plain = true })

    -- merge first part onto existing last line
    parts[1] = last_line .. parts[1]

    -- replace from last line onward
    vim.api.nvim_buf_set_lines(
        state.buf,
        line_count - 1,
        line_count,
        false,
        parts
    )

    -- scroll to bottom
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        local new_count = vim.api.nvim_buf_line_count(state.buf)
        vim.api.nvim_win_set_cursor(state.win, { new_count, 0 })
    end
end


function M.finish(response)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end
    vim.bo[state.buf].modifiable = false
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
    end
end

function M.resize()
    local win = state.win
    if not win or not vim.api.nvim_win_is_valid(win) then return end

    local width = math.floor(vim.o.columns * 0.7)
    local height = math.floor(vim.o.lines * 0.7)

    vim.api.nvim_win_set_config(win, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
    })
end

function M.get_win() return state.win end
function M.get_buf() return state.buf end

return M
