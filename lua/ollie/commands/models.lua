local M = {}

--core
local selector = require("ollie.core.selector")
local router   = require("ollie.core.router") 

--ui
local notify = require("ollie.ui.notify")


--[[
1. functions

2. commands
2.1 :OllieModel <model_name>
2.2 :OllieProvider <provider_name>
2.3 :OllieListModels
2.4 :OllieListProviders
2.5 :OllieTestModel <model_name>



]]

-------------------------------
-- Model Switching
-------------------------------

local function create_model_command()

    vim.api.nvim_create_user_command(
        
    "OllieModel",

        function(opts)
            local model = vim.trim(opts.args or "")

            if model == "" then
                vim.notify(
                    "Usage: :OllieModel <model_name>  (e.g. llama3:latest)",
                    vim.log.levels.WARN,
                    { title = "Ollie" }
                )
                return
            end

            selector.set_model(model)

            notify.switched(
                "model",
                model
            )
            
        end,

        {
            nargs = "?",
        }
    )
end

---------------------------
-- Model Listing
---------------------------

local function list_models_command()

    vim.api.nvim_create_user_command(
        "OllieListModels",
        function()
            local models = selector.list_models()

            if not models or #models == 0 then
                vim.notify(
                    "No models available.",
                    vim.log.levels.INFO,
                    { title = "Ollie" }
                )
                return
            end

            notify.list("Available Models", models)
        end,
        {
            nargs = 0,
        }
    )
end


-----------------------
-- Provider Switching
-----------------------

local function create_provider_command()

    vim.api.nvim_create_user_command(
        "OllieProvider",
        function(opts)
            local provider = vim.trim(opts.args or "")

            if provider == "" then
                vim.notify(
                    "Usage: :OllieProvider <provider_name>  (e.g. ollama, openai)",
                    vim.log.levels.WARN,
                    { title = "Ollie" }
                )
                return
            end

            selector.set_provider(provider)
            notify.switched("provider", provider)
        end,
        { 
            nargs = "?",
         }
    )
end


----------------------
-- Provider Listing
----------------------

local function create_list_providers_command()

    vim.api.nvim_create_user_command(
        "OllieListProviders",
        function()
            local providers = selector.list_providers()

            if not providers or #providers == 0 then
                vim.notify(
                    "No providers registered. Add providers in your setup() config.",
                    vim.log.levels.INFO,
                    { title = "Ollie" }
                )
                return
            end

            notify.list("Available providers", providers)
        end,
        {
        nargs = 0,
        }
    )
end





function M.setup()
    create_model_command()
    list_models_command()
    create_provider_command()
    create_list_providers_command()
end

return M