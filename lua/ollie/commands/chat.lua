local M = {}

local session = require("ollie.core.session")
local buff = require("ollie.core.context.buff")

-- ui backends
local session_ui = require("ollie.ui.session_ui")
local do_task = require("ollie.ui.behaviour.task_router")


--------------------------------------------------
-- :OllieChat (no context)
--------------------------------------------------
local function create_chat_command()

    vim.api.nvim_create_user_command(
        "OllieChat",
        function(opts)

            session.start("chat")

            do_task.chat(
                opts.args or "",
                {
                    include_context = false,
                }
            )
        end,
        {
            nargs = "*",
        }
    )
end

--------------------------------------------------
-- :OllieChatContext (with context)
--------------------------------------------------
local function create_chat_context_command()

    vim.api.nvim_create_user_command(
        "OllieChatContext",
        function(opts)

            session.start("chat")

            do_task.chat(
                opts.args or "",
                {
                    include_context = true,
                    context = buff.get_context(),
                }
            )
        end,
        {
            nargs = "*",
        }
    )
end

--------------------------------------------------
-- session commands
--------------------------------------------------
local function create_session_commands()

    vim.api.nvim_create_user_command(
        "OllieSessions",
        function()
            session_ui.open()
        end,
        {}
    )

    vim.api.nvim_create_user_command(
        "OllieSessionDelete",
        function(opts)
            session.delete(opts.args ~= "" and opts.args or nil)
        end,
        {
            nargs = "?",
        }
    )

    vim.api.nvim_create_user_command(
        "OllieSessionClear",
        function()
            session.clear()
        end,
        {}
    )

end

-- setup
function M.setup(opts)
    create_chat_command()
    create_chat_context_command()
    create_session_commands()
end

return M
