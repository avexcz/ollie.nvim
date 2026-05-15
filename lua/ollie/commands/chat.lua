local M = {}

local ollama = require("ollie.providers.ollama.model")
local selector = require("ollie.core.selector")
local context = require("ollie.handler.context.buff")
local float = require("ollie.ui.front")

local function create_chat_command() -- created chat command (:OllieChat) to interact with the AI, it takes the user query as an argument and sends it to the selected model along with the current buffer context, then displays the response in a window.
    vim.api.nvim_create_user_command(
        "OllieChat",
        function(opts) -- function to handle the command execution.
            local query = opts.args -- get the user query from the command arguments.

            if query == "" then
                vim.notify(
                    "Please provide a query.",
                    vim.log.levels.WARN,
                    { title = "Ollie" }
                )
                return
            end

            local ctx = context.get_context() -- get the current buffer context, including content, cursor position, and file type from "ollie/handler/context/buff.lua".

            query = query
                .. "\n\nContext:\n"
                .. ctx.buffer_content -- include the current buffer content as context for the AI to generate a more relevant response.

            vim.notify(
                "Thinking...",
                vim.log.levels.INFO,
                { title = "Ollie" }
            )

            local model = selector.get_model() or "avexcoder_3b:latest" -- get the currently selected model from "ollie/core/selector.lua", default to "qwen2.5-coder:3b" if no model is selected.

            ollama.generate(model, query, function(response) -- call the generate function from "ollie/providers/ollama/model.lua" to send the query and context to the selected model and get the response.
                vim.schedule(function() -- schedule the UI update on the main thread.
                    if response == "Ollama offline" then
                        vim.notify(
                            "Ollama server is not running. Please start the server or switch to a cloud AI model.",
                            vim.log.levels.ERROR,
                            { title = "Ollie" }
                        )
                        return
                    end

                    float.open(response) -- display the AI response in a floating window using "ollie/ui/front.lua".
                end)
            end)

        end,
        {
            nargs = "*", -- number of arguments (0 or more) to allow for the query.
        }
    )
end

local function create_model_command()  -- created model command (:OllieModel <model_name>) to switch between models
    vim.api.nvim_create_user_command(
        "OllieModel",
        function(opts)
            local model = opts.args

            if model == "" then
                vim.notify(
                    "Please provide a model name.",
                    vim.log.levels.WARN,
                    { title = "Ollie" }
                )
                return
            end

            selector.set_model(model)

            vim.notify(
                "Switched to model: " .. model,
                vim.log.levels.INFO,
                { title = "Ollie" }
            )
        end,
        {
            nargs = 1,
        }
    )
end

--  :h ollie for more details on how to use the commands and switch between models, also check the README for examples and documentation. 



-- setup function to create the commands when the plugin is loaded
function M.setup()
    create_chat_command()
    create_model_command()
 
end

return M