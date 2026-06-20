local M = {}

-- core
local router = require("ollie.core.router")
local session = require("ollie.core.session")
local runtime = require("ollie.core.runtime")
local response_text = require("ollie.core.response")

--format
local selection = require("ollie.core.context.selection")
local render = require("ollie.ui.render")

-- ui
local notify = require("ollie.ui.notify")
local window = require("ollie.ui.windows.window")

-- prompt + validation
local prompt_builder = require("ollie.handler.explain.prompt")
local validate = require("ollie.handler.explain.validate")

----------------------------------------------------
-- Explain execution layer
---------------------------------------------------
function M.run_explain(query, selected_code, opts)
    if type(selected_code) == "table" and opts == nil then
        opts = selected_code
        selected_code = nil
    end

    opts = opts or {}
    selected_code = selected_code or selection.get_selected_code()
    
    -- validate
    local ok, err = validate.explain(query, selected_code)

    if not ok then

        vim.notify(
            err,
            vim.log.levels.WARN,
            { title = "Ollie" }
        )

        return
    end

    --store user message
    session.add("user",  {
        query = query,
        code = selected_code
    })

    -- runtime config
    local provider = runtime.provider(opts)
    local model = runtime.model(opts)
    
    -- build prompt
    local prompt = prompt_builder.explain(
        query,
        selected_code
    )

    -- open panel
    window.open("explain")

    -- display the code being explained
    window.append("explain", render.format_query(query, selected_code))

    -- notify loading
    notify.running(
        provider,
        model,
        "explain"
    )

    local streamed = false

    -- execute request
    router.request({

        task = "explain",
        provider = provider,
        model = model,
        prompt = prompt,
        stream = runtime.streaming(opts),

        -- streaming chunks
        on_chunk = function(chunk)
            streamed = true

            vim.schedule(function()
                window.append("explain", render.chunk(chunk))
            end)

        end,

        -- completion
        on_complete = function(response)

            vim.schedule(function()
                if streamed then
                    window.append("explain", render.ollie_end(model))
                else
                    window.append("explain", render.complete(response, model))
                end
                window.finish("explain")

                session.add("assistant", response_text.text(response))
            end)
        end,

        -- error handling
        on_error = function(err)

            vim.schedule(function()
                window.append("explain", render.error(err))
                window.finish("explain")
            end)
        end,
    })
end

return M
