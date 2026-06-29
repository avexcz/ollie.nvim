local M = {}

M.name = "Ollie"
M.version = "0.1.0"
M.author = "Avex"

-- safety wrapper for require to handle missing modules
local function safe_require(name)
    local ok, mod = pcall(require, name)
    if not ok then
        vim.notify("Ollie failed loading: " .. name .. "\n" .. mod, vim.log.levels.ERROR)
        return nil
    end
    return mod
end

-- core
local session = safe_require("ollie.core.session")
local config = safe_require("ollie.core.config")
local router = safe_require("ollie.router.provider")

-- system security
local security = safe_require("ollie.system.security")
local health = safe_require("ollie.commands.hardware")

-- Backends
local resize = safe_require("ollie.ui.behaviour.resize")
local chat_command = safe_require("ollie.commands.chat")
local debug_command = safe_require("ollie.commands.debug")
local model_command = safe_require("ollie.commands.models")
local help_command = safe_require("ollie.commands.help")

--greetings
local function greeting()
    return {
        "",
        "",
        [[   .---.  ,-.    ,-.    ,-.,---.      ]],
        [[  / .-. \ | |    | |    | || .-'      ]],
        [[  | | | | | |    | |    | || `-.      ]],
        [[  | | | | | |    | |    | || .-'      ]],
        [[  \ `-' / | `--. | `--. | ||  `--.    ]],
        [[ ./\---'  _/\ __.'/\ __.'`-'/\ __.'    ]],
        [[ (__)     (__)   (__)      (__)        ]],
        "",
        "Welcome! Hit return to punch me with your query!   ",
        "Do :OllieHelp for documentation and configuration! ",
        "",
    }
end

-- colour greeting with highlights
local function colorize_greeting(buf, start_line)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Define highlight groups
    vim.cmd("highlight OllieArt guifg=#87CEEB gui=bold") -- SKy blue for ASCII art
    vim.cmd("highlight OllieWet guifg=#00CCFF gui=bold") -- Cyan for water
    vim.cmd("highlight OllieWelcome guifg=#FFFFFF gui=italic") -- Cyan for welcome text


    -- colour the ASCII art
    for i = 2, 7 do
        vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            "OllieArt",
            start_line + i - 1,
            0,
            -1
        )
    end

    -- colour the water ASCII art (line 8)
    for j = 7, 8 do
    vim.api.nvim_buf_add_highlight(
        buf,
        -1,
        "OllieWet",
        start_line + j - 1,
        0,
        -1
    )
    end

    -- colour the welcome text (line 9)
    for k = 10, 12 do
    vim.api.nvim_buf_add_highlight(
        buf,
        -1,
        "OllieWelcome",
        start_line + k - 1,
        0,
        -1
    )
    end
end

-- validate critical modules are loaded before proceeding
local function validate_modules()
    if not chat_command then
        vim.notify("Critical module missing: ollie.commands.chat", vim.log.levels.ERROR)
        return false
    end
    return true
end

-- command to open Ollie's interactive window
vim.api.nvim_create_user_command("Ollie", function()

    if not validate_modules() then
        return
    end

    local chat = require("ollie.handler.chat")
    local input = require("ollie.ui.behaviour.input")
    local window = require("ollie.ui.windows.window")
    local session = require("ollie.core.session")

    -- update session
    session.start("chat")
    -- open window
    window.open("chat")
    window.clear("chat")
    local buf = window.get_buf("chat")

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.notify(
            "Failed to create chat buffer",
            vim.log.levels.ERROR,
            { title = "Ollie" }
        )
        return
    end

    -- add greeting only for new/empty buffer
    if vim.api.nvim_buf_line_count(buf) <= 1 then
        local greeting_text = table.concat(greeting(), "\n")

        local start_line = vim.api.nvim_buf_line_count(buf)

        window.append("chat", greeting_text)
        colorize_greeting(buf, start_line)
    end

    local greeted = true
    -- submit function
    local function submit(user_input)

        user_input = vim.trim(user_input or "")

        if user_input == "" then
            window.append(
                "chat",
                "⚠️  Ollie: Please enter a valid query.\n"
            )

            input.finish()
            return
        end

        -- clear greeting once
        if greeted then
            window.clear("chat")
            greeted = false
        end
        
        local ok, err = pcall(function()
            chat.dispatch_chat(user_input, {
                include_context = false,

                on_complete = function()
                    input.finish()
                end,

                on_error = function()
                    input.finish()
                end,
            })

        end)

        if not ok then
            input.finish()

            vim.notify(
                err,
                vim.log.levels.ERROR,
                { title = "Ollie" }
            )
        end
    end

    input.attach(buf, submit)
    input.ask(submit)

end, {})

-- function to check neovim's version
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

-- setup function to initialize Ollie
function M.setup(opts)
    opts = opts or {}

    if config and config.setup then config.setup(opts) end
    if router and router.setup then router.setup(opts.router) end
    if security and security.setup then security.setup(opts.security) end
    if resize and resize.setup then resize.setup() end
    if chat_command and chat_command.setup then chat_command.setup(opts) end
    if debug_command and debug_command.setup then debug_command.setup(opts) end
    if health and health.setup then health.setup(opts) end
    if model_command and model_command.setup then model_command.setup(opts) end
    if help_command and help_command.setup then help_command.setup(opts) end
end

-- session API exposure
if session then
    M.session = {
        start = session.start,
        switch = session.switch,
        delete = session.delete,
        list = session.list,
        clear = session.clear,
        current = session.get_active,
    }
end

return M
