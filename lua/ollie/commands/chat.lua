local M = {}


-- handlers
local chat = require("ollie.handler.chat")

-- state
local config = require("ollie.core.config")
local session = require("ollie.core.session")

--UI layer
local session_ui = require("ollie.ui.session_ui")

--UI setup
local RENDER = {
    CHAT = "chat",
    PANEL = "panel",
}


--[[
List:
1. functions
1.1 run_chat() >> ollie/handler/chat 
1.2 run_fix() >> ollie/handler/debug

2. commands
2.1 :OllieChat
2.2 :OllieCHAT
2.3 :OllieFix

]]



    -- provider routing
    -- if provider == "ollama" then

    --     ollama.generate(
    --         model,
    --         query,
    --         handle_response
    --     )
    -- elseif provider == "openai" then
    --     openai.generate(
    --         model,
    --         query,
    --         handle_response
    --     )
    -- elseif provider == "anthropic" then
    --     anthropic.generate(
    --         model,
    --         query,
    --         handle_response
    --     )
    -- else
    --     vim.notify(
    --         "Unknown provider: " .. provider,
    --         vim.log.levels.ERROR,
    --         { title = "Ollie" }
    --     )
    -- end


--------------------------------------------------
-- :OllieChat (lightweight chat without full context)
--------------------------------------------------
local function create_chat_command()

    vim.api.nvim_create_user_command(
        "OllieChat",
        function(opts)

            chat.run_chat(
                opts.args or "",
                {
                    include_context = false,
                    render = RENDER.CHAT,
                }
            )
        end,

        {
        nargs = "*",
        }
    )
end

-----------------------------------------
-- :OllieCHAT (sends full buffer context)
-----------------------------------------

local function create_chat_context_command()

    vim.api.nvim_create_user_command(
         "OllieCHAT",
         function(opts) 

            chat.run_chat(opts.args or "",
            {
                include_context = true,
                render = RENDER.CHAT,
            }
        )
        end,

        {
            nargs = "*",
        }
    )
end

------------------------------
-- session management commands
------------------------------
local function create_session_commands()

    vim.api.nvim_create_user_command("OllieSessions", function()
        session_ui.open()
    end, {})

    vim.api.nvim_create_user_command("OllieSessionClose", function()
        session.close()
    end, {})

    vim.api.nvim_create_user_command("OllieSessionDelete", function()
        session.delete()
    end, {})

    vim.api.nvim_create_user_command("OllieSessionClear", function()
        session.clear()
    end, {})

    vim.api.nvim_create_user_command("OllieSessionSwitch", function(opts)
        session.switch(opts.args)
    end, {
        nargs = 1,
    })

end



--------
-- setup
--------

function M.setup(opts)
    
    config.setup(opts)

    create_chat_command()
    create_chat_context_command()
    create_session_commands()

end

return M

