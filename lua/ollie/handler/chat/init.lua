local M = {}

-- handler modules
local validate = require("ollie.handler.chat.validate")
local prompt_builder = require("ollie.handler.chat.prompt")


-- core
local router = require("ollie.core.router")
local events = require("ollie.core.events")
local session = require("ollie.core.session")

-- state
local config = require("ollie.core.config")
local selector = require("ollie.core.selector")

-- ui
local render = require("ollie.ui.render")
local notify = require("ollie.ui.notify")
local float = require("ollie.ui.front")



-- render modes
local RENDER = {
    CHAT = "chat",
    PANEL = "panel",
}


-- helpers
local function resolve_provider()
    return selector.get_provider() or config.get("default_provider")
end

local function resolve_model()
    return selector.get_model() or config.get("default_model")
end

-----------------------
-- chat execution layer
-----------------------
function M.run_chat(query, opts)
    opts = opts or {}

    -- validate query
    local ok, err = validate.query(query)

    if not ok then

        vim.notify(
            err,
            vim.log.levels.WARN,
            { title = "Ollie" }
        )

        return
    end

    --session started
    events.emit("new_chat", {
        mode = "chat",
        input = query,
    })

    events.emit("user_message", query)

    -- build prompt
    local prompt = prompt_builder.build(query, {
        include_context = opts.include_context,
    })


    -- resolve runtime settings
    local provider = resolve_provider()
    local model = resolve_model()

    local render_mode = opts.render
        or config.get("render_mode")
        or RENDER.CHAT

    local buf = nil
    if render_mode == RENDER.CHAT then
        buf = float.open()
    end

    -- notify loading
    notify.running(
        provider,
        model,
        "chat"
    )


    -- execute request
    router.request({

        task = "chat",
        buf = buf,
        provider = provider,
        model = model,
        prompt = prompt,
        stream = config.get("streaming"),


        -- streaming chunks
        on_chunk = function(chunk)

            vim.schedule(function()
                render.chunk(
                    render_mode,
                    chunk
                )
                events.emit("stream_chunk", {
                    task = "chat",
                    chunk = chunk,
                })
            end)
        end,


        -- completion
        on_complete = function(response)

            vim.schedule(function()
                render.complete(
                    render_mode,
                    response
                )
                events.emit("assistant_message", {
                    task = "chat",
                    content = response,
                })
            end)
        end,


        -- error handling
        on_error = function(err)
            
            vim.schedule(function()
                render.error(err)
                events.emit("error", err)
            end)
        end,
    })
end

return M