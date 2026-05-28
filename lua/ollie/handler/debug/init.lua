local M = {}

-- core
local router = require("ollie.core.router")
local config = require("ollie.core.config")
local selector = require("ollie.core.selector")
local events = require("ollie.core.events")
local session = require("ollie.core.session")

-- prompt + validation
local prompt_builder = require("ollie.handler.debug.prompt")
local validate = require("ollie.handler.debug.validate")


-- helpers
local function resolve_provider()
    return selector.get_provider() or config.get("default_provider")
end

local function resolve_model()
    return selector.get_model() or config.get("default_model")
end

------------------------
-- debug execution layer
------------------------
function M.run_fix(query, selected_code, opts)
    opts = opts or {}

    -- validation
    local ok, err = validate.fix(query, selected_code)
    if not ok then
        vim.notify(err, vim.log.levels.WARN, { title = "Ollie" })
        return
    end

    -- session
    session.start("fix")

    -- runtime config
    local provider = resolve_provider()
    local model = resolve_model()

    -- prompt
    local prompt = prompt_builder.fix(query, selected_code)

    -- user message
    events.emit("user_message", query)

    -- task start
    events.emit("task_start", {
        task = "fix",
        provider = provider,
        model = model,
    })

    -- request
    router.request({
        task = "fix",
        provider = provider,
        model = model,
        prompt = prompt,
        stream = config.get("streaming"),


        -- streaming
        on_chunk = function(chunk)
            vim.schedule(function()
                events.emit("stream_chunk", {
                    task = "fix",
                    text = chunk,
                })
            end)
        end,


        -- completion
        on_complete = function(response)
            vim.schedule(function()
                events.emit("task_complete", {
                    task = "fix",
                    text = response,
                })

                events.emit("assistant_message", response)
            end)
        end,


        -- error
        on_error = function(err)
            vim.schedule(function()
                events.emit("task_error", {
                    task = "fix",
                    error = err,
                })
            end)
        end,
    })
end

return M