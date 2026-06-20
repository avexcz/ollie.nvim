local M = {}

-- load engines
local session = require("ollie.core.session")
local window = require("ollie.ui.windows.window")
local render = require("ollie.ui.render")

-- states
local state = {
    buf = nil,
    win = nil,
    rows = {},
}

-- local list the active ids
local function get_active_id()
    local active = session.get_active()
    return active and active.id
end

-- local render list
local function render_list()
    local list = session.list()
    local active_id = get_active_id()

    local lines = { " Ollie Sessions ", "----------------" }
    state.rows = {}

    for _, s in ipairs(list) do
        local mark = (s.id == active_id) and "●" or "○"
        local line = #lines + 1
        state.rows[line] = s.id

        table.insert(lines, string.format(
            "%s %s [%s] msgs:%d",
            mark,
            s.id,
            s.mode,
            s.message_count or 0
        ))
    end

    return lines
end

-- refesh engine
local function refresh()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        return
    end

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, render_list())
    vim.bo[state.buf].modifiable = false
end

local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    state.win = nil
end

local function render_message(message)
    if type(message) ~= "table" then
        return tostring(message or "")
    end

    if message.role == "assistant" then
        return render.complete(message.content)
    end

    if message.role == "user" then
        return render.user(message.content)
    end

    return tostring(message.content or "")
end

local function open_chat(id)
    if not id then
        return
    end

    session.switch(id)

    local current = session.get(id)
    if not current then
        vim.notify("Invalid session: " .. tostring(id), vim.log.levels.WARN, { title = "Ollie" })
        return
    end

    window.close("chat")

    local buf, win = window.open("chat", nil, { reset = true })
    if not buf or not win then
        return
    end

    for _, message in ipairs(current.messages or {}) do
        window.append("chat", render_message(message))
    end

    session.set_window(buf, win)
    close()
end

local function close_chat()
    window.close("chat")
    session.set_window(nil, nil)
end

local function selected_session_id()
    if not state.win or not vim.api.nvim_win_is_valid(state.win) then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(state.win)
    return state.rows[cursor[1]]
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

    refresh()

    vim.keymap.set("n", "r", function()
        refresh()
    end, { buffer = state.buf })

    vim.keymap.set("n", "<CR>", function()
        open_chat(selected_session_id())
    end, { buffer = state.buf })

    -- group of keymaps for session UI 
    vim.keymap.set("n", "x", close_chat, { buffer = state.buf })
    vim.keymap.set("n", "q", close, { buffer = state.buf })
    vim.keymap.set("n", "<Esc>", close, { buffer = state.buf })
end

return M
