local M = {}

local formatter = require("ollie.ui.behaviour.format")

local function apply_options(win)
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
end

function M.open(buf, config)
    local win = vim.api.nvim_open_win(buf, true, config)
    apply_options(win)
    pcall(formatter.format, win)

    return win
end

return M
