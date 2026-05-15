local M = {}

M.name = "Ollie"
M.version = "0.1.0"
M.author = "Avex"


local chat = require("ollie.commands.chat")

-- Neovim version check
local function version_check()
    if vim.fn.has("nvim-0.10") == 0 then
        vim.notify(
            "Ollie requires Neovim >= 0.10",
            vim.log.levels.ERROR,
            { title = "Ollie" }
        )

        return false
    end

    return true
end

if not version_check() then
    return M
end

-- Plugin setup
function M.setup(opts)
    opts = opts or {}



    chat.setup()
end

return M