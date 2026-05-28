local M = {}

M.name = "Ollie"
M.version = "0.1.0"
M.author = "Avex"

local function safe_require(name)
    local ok, mod = pcall(require, name)
    if not ok then
        vim.notify("Ollie failed loading: " .. name .. "\n" .. mod, vim.log.levels.ERROR)
        return nil
    end
    return mod
end

local events = safe_require("ollie.core.events")
local session = safe_require("ollie.core.session")
local resize = safe_require("ollie.ui.behaviour.resize")
local chat = safe_require("ollie.commands.chat")
local debug = safe_require("ollie.commands.debug")

local function version_check()
    if vim.fn.has("nvim-0.10") == 0 then
        vim.notify("Ollie requires Neovim >= 0.10", vim.log.levels.ERROR)
        return false
    end
    return true
end

if not version_check() then
    return M
end

function M.setup(opts)
    opts = opts or {}

    if resize and resize.setup then resize.setup() end
    if chat and chat.setup then chat.setup(opts) end
    if debug and debug.setup then debug.setup(opts) end
end

-- safe session API exposure
if session then
    M.session = {
        start = session.start,
        switch = session.switch,
        delete = session.delete,
        list = session.list,
        clear = session.clear,
        current = session.get_active, -- FIXED
    }
end

return M