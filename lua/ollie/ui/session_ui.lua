local M = {}

local session = require("ollie.core.session")

local state = {
    buf = nil,
    win = nil,
}

local function get_active_id()
    local active = session.get_active()
    return active and active.id
end

local function render_list()
    local list = session.list()
    local active_id = get_active_id()

    local lines = { " Ollie Sessions ", "----------------" }

    for _, s in pairs(list) do
        local mark = (s.id == active_id) and "●" or "○"

        table.insert(lines, string.format(
            "%s %s [%s] msgs:%d",
            mark,
            s.id,
            s.mode,
            #(s.messages or {})
        ))
    end

    return lines
end

function M.open()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)
    end

    local width = math.floor(vim.o.columns * 0.5)
    local height = math.floor(vim.o.lines * 0.5)

    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Ollie Sessions ",
        title_pos = "center",
    })

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, render_list())
    vim.bo[state.buf].modifiable = false

    vim.keymap.set("n", "r", function()
        vim.bo[state.buf].modifiable = true
        vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, render_list())
        vim.bo[state.buf].modifiable = false
    end, { buffer = state.buf })

    vim.keymap.set("n", "q", function()
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            vim.api.nvim_win_close(state.win, true)
        end
    end, { buffer = state.buf })
end

return M