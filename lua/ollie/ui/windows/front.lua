local M = {}

local formatter = require("ollie.ui.behaviour.format")

function M.open(buf, config)
    local win = vim.api.nvim_open_win(buf, true, config)
    pcall(formatter.format, win)
    return win
end

return M
