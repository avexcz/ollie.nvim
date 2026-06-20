local M = {}

local front = require("ollie.ui.windows.front")
local panel = require("ollie.ui.windows.panel")
local input = require("ollie.ui.behaviour.input")
local cursor = require("ollie.ui.behaviour.cursor_controller")

local modes = {
    chat = { kind = "front" },
    panel = { kind = "panel" },
    fix = { kind = "panel" },
    explain = { kind = "panel" },
}

local state = {}

for mode, spec in pairs(modes) do
    state[mode] = {
        kind = spec.kind,
        buf = nil,
        win = nil,
        position = spec.position or "right",
    }
end

local function is_valid_buf(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_valid_win(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function get(mode)
    return state[mode]
end

local function panel_border()
    return {
        "┌", "─", "┐", "│",
        "┘", "─", "└", "│",
    }
end

local function front_config()
    local width = math.floor(vim.o.columns * 0.7)
    local height = math.floor(vim.o.lines * 0.7)

    return {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = "Ollie AI",
        title_pos = "center",
        noautocmd = true,
    }
end

local function panel_config(position)
    position = position or "right"

    local width = math.floor(vim.o.columns * 0.30)
    local height = vim.o.lines - 2

    return {
        relative = "editor",
        width = width,
        height = height,
        row = 1,
        col = position == "left" and 0 or (vim.o.columns - width),
        style = "minimal",
        border = panel_border(),
        title = " Ollie AI",
        title_pos = "center",
        noautocmd = true,
    }
end

local function window_config(s)
    if s.kind == "front" then
        return front_config()
    end

    return panel_config(s.position)
end

local function configure_buffer(buf)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].buflisted = false
end

local function reset_buffer(buf)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    vim.bo[buf].modifiable = false
end

local function ensure_buffer(s, reset)
    if not is_valid_buf(s.buf) then
        s.buf = vim.api.nvim_create_buf(false, true)
        configure_buffer(s.buf)
        reset = true
    end

    if reset then
        reset_buffer(s.buf)
    end

    return s.buf
end

local function open_window(s)
    if is_valid_win(s.win) then
        return s.win
    end

    if s.kind == "front" then
        s.win = front.open(s.buf, window_config(s))
    else
        s.win = panel.open(s.buf, window_config(s))
    end

    return s.win
end

local function attach_close_key(mode, buf)
    vim.keymap.set("n", "q", function()
        M.close(mode)
    end, {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = "Close Ollie window",
    })
end

local function ensure_open(mode)
    local s = get(mode)
    if not s then
        return nil
    end

    if is_valid_buf(s.buf) and is_valid_win(s.win) then
        return s
    end

    M.open(mode)
    return get(mode)
end

function M.open(mode, send_fn, opts)
    mode = mode or "chat"
    opts = opts or {}

    local s = get(mode)
    if not s then
        vim.notify("Unknown Ollie window mode: " .. tostring(mode), vim.log.levels.WARN, { title = "Ollie" })
        return nil, nil
    end

    if opts.position then
        s.position = opts.position
    end

    local buf = ensure_buffer(s, opts.reset == true)
    local win = open_window(s)

    attach_close_key(mode, buf)

    if send_fn then
        input.attach(buf, send_fn, function()
            cursor.reset(win)
        end)
    end

    return buf, win
end

function M.append(mode, text)
    -- mode
    local s = ensure_open(mode)
    if not s or not is_valid_buf(s.buf) then
        return
    end

    --text
    text = tostring(text or "")
    if text == "" then
        return
    end

    vim.bo[s.buf].modifiable = true

    local line_count = vim.api.nvim_buf_line_count(s.buf)
    local last_line = vim.api.nvim_buf_get_lines(s.buf, line_count - 1, line_count, false)[1] or ""
    local lines = vim.split(text, "\n", { plain = true })

    lines[1] = last_line .. lines[1]

    vim.api.nvim_buf_set_lines(s.buf, line_count - 1, line_count, false, lines)
    vim.bo[s.buf].modifiable = false

    if is_valid_win(s.win) then
        local last = vim.api.nvim_buf_line_count(s.buf)
        vim.api.nvim_win_set_cursor(s.win, { last, 0 })
    end
end

function M.clear(mode, text)
    local s = get(mode)
    if not s or not is_valid_buf(s.buf) then
        return
    end

    vim.bo[s.buf].modifiable = true
    vim.api.nvim_buf_set_lines(
        s.buf,
        0,
        -1,
        false,
        text and { text } or {}
    )
    vim.bo[s.buf].modifiable = false
end

function M.finish(mode)
    local s = get(mode)
    if not s or not is_valid_buf(s.buf) then
        return
    end

    vim.bo[s.buf].modifiable = false
end

function M.close(mode)
    local s = get(mode)
    if not s then
        return
    end

    if is_valid_win(s.win) then
        vim.api.nvim_win_close(s.win, true)
    end

    s.win = nil
    s.buf = nil
end

function M.resize(mode)
    local s = get(mode)
    if not s or not is_valid_win(s.win) then
        return
    end

    vim.api.nvim_win_set_config(s.win, window_config(s))
end

function M.resize_all()
    for mode, _ in pairs(state) do
        M.resize(mode)
    end
end

function M.get_buf(mode)
    local s = get(mode)
    return s and s.buf
end

function M.get_win(mode)
    local s = get(mode)
    return s and s.win
end

function M.get_state()
    return state
end

return M
