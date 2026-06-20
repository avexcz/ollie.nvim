local M = {}

-- handler modules
local validate = require("ollie.handler.chat.validate")
local prompt_builder = require("ollie.handler.chat.prompt")


-- core
local router = require("ollie.core.router")
local session = require("ollie.core.session")
local runtime = require("ollie.core.runtime")
local response_text = require("ollie.core.response")
local buff = require("ollie.core.context.buff")

-- ui
local notify = require("ollie.ui.notify")
local window = require("ollie.ui.windows.window")
local render = require("ollie.ui.render")
local input = require("ollie.ui.behaviour.input")


-- verify if context is included or not. Default nil if file missing. Priority: opts.context > buff.get_context().
local function resolve_context(opts)
    if not opts.include_context then
        return nil
    end

    return opts.context or buff.get_context()
end

-- warn if any broken module occured
local function fail(opts, err)
    vim.notify(err, vim.log.levels.WARN, { title = "Ollie" })

    if type(opts.on_error) == "function" then
        opts.on_error({ error = err })
    end
end

--------------------------------------------------
-- chat execution layer
--------------------------------------------------
function M.dispatch_chat(query, opts)
    opts = opts or {}

    -- load user input data
    local ctx = {
        query = query,
        include_context = opts.include_context,
        content = opts.content,
        context = resolve_context(opts),
    }
    -- validation
    local ok, err = validate.query(ctx.query)

    if not ok then
        fail(opts, err)
        return false
    end

    -- store user data
    session.add("user", ctx.query)


    -- build prompt
    local prompt = prompt_builder.build(ctx.query, {
        include_context = ctx.include_context,
        context = ctx.context,
    })

    -- runtime config
    local provider = runtime.provider(opts)
    local model = runtime.model(opts)

    --ui unit
    window.open("chat")
    --display the user query
    window.append("chat", render.format_query(ctx.query))

    -- notify loading
    notify.running(
        provider,
        model,
        "chat"
    )

    local streamed = false

    -- execute request
    return router.request({
        task = "chat",
        provider = provider,
        model = model,
        prompt = prompt,
        stream = runtime.streaming(opts),

        -- streaming chunks
        on_chunk = function(chunk)
            streamed = true

            vim.schedule(function()
                window.append("chat", render.chunk(chunk)) -- apend and render the chunk
            end)
        end,


        -- completion
        on_complete = function(response)
            vim.schedule(function()

                if streamed then
                    window.append("chat", render.ollie_end(model)) -- end ollie session if streamed
                else
                    window.append("chat", render.complete(response, model))
                end

                window.finish("chat")

                session.add(
                    "assistant",
                    response_text.text(response)
                )

                if opts.on_complete then
                    opts.on_complete(response)
                end
            end)
        end,


        -- error handling
        on_error = function(err)
            vim.schedule(function()

                window.append("chat", render.error(err))
                window.finish("chat")

                if opts.on_error then
                    opts.on_error(err)
                end
            end)
        end,
    })
end

-- entry point for running a chat interaction
function M.run_chat(query, opts)
    opts = opts or {}
    local context = opts.context

    -- get the context details if context is included
    if opts.include_context and not context then
        context = buff.get_context()
    end

    local function finish_input()
        input.finish()
    end

    local function on_complete(response)
        finish_input()

        if type(opts.on_complete) == "function" then
            opts.on_complete(response)
        end
    end

    local function on_error(err)
        finish_input()

        if type(opts.on_error) == "function" then
            opts.on_error(err)
        end
    end

    window.open("chat", function(user_input)
        M.dispatch_chat(user_input, {
            include_context = opts.include_context,
            context = context,
            provider = opts.provider,
            model = opts.model,
            stream = opts.stream,
            on_complete = on_complete,
            on_error = on_error,
        })
    end)

    if query and vim.trim(query) ~= "" then
        local dispatch_opts = vim.tbl_extend("force", {}, opts, {
            context = context,
            on_complete = on_complete,
            on_error = on_error,
        })

        return M.dispatch_chat(query, dispatch_opts)
    end

    return true
end

return M
