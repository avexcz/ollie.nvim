
-- model router for dispatching requests to providers based

local M = {}

local providers = require("ollie.providers")
local permission = require("ollie.system.security.permission")
local selector = require("ollie.router.selector")

-- routing traffic control rules
local defaults = { 
    stream = true,
}

    -- chat = {
    --     provider = "ollama",
    --     model = "avexcoder_3b:latest",
    -- },

    -- autocomplete = {
    --     provider = "ollama",
    --     model = "qwen2.5-coder:1.5b",
    -- },

    -- fix = {
    --     provider = "ollama",
    --     model = "avexcoder_3b:latest",
    -- },

    -- reasoning = {
    --     provider = "anthropic",
    --     model = "claude-opus-4-5",
    --},
local rules = {

    chat = {
        provider = "ollama",
        model = "avexcoder_3b:latest",
    },

    fix = {
        provider = "ollama",
        model = "avexcoder_3b:latest",
    },

    autocomplete = {
        provider = "ollama",
        model = "avexcoder_3b:latest",
    },

    explain = {
        provider = "ollama",
        model = "avexcoder_3b:latest",
    }
}


local function notify_error(message, title, on_error)
    vim.notify(message, vim.log.levels.ERROR, { title = title or "Ollie Router" })

    if type(on_error) == "function" then
        on_error({ error = message })
    end
end

local function notify_warn(message, title, on_error)
    vim.notify(message, vim.log.levels.WARN, { title = title or "Ollie Router" })

    if type(on_error) == "function" then
        on_error({ error = message })
    end
end

-- validate routing rule asynchronously to prevent blocking UI
local function validate_route(route, task, on_error)
    if not route then
        notify_error(
            "No routing rule for task: '" .. tostring(task) .. "'."
            .. " Register one with router.register_rule().",
            "Ollie Router",
            on_error
        )
        return false
    end
    return true
end


-- main request dispatcher
function M.request(opts)
    opts = opts or {}

    -- request metadata and resolve routing
    local task = opts.task or "chat"
    local route = rules[task]

    if not validate_route(route, task, opts.on_error) then
        return false
    end

    
    -- provider/model resolution
    local provider_name = opts.provider or selector.get_provider() or route.provider
    local model = opts.model or selector.get_model() or route.model
    local provider = providers.get(provider_name)

    if not provider or type(provider.generate) ~= "function" then
        notify_error(
            "Provider '" .. tostring(provider_name) .. "' is unavailable"
            .. " or missing a generate() function.",
            "Ollie Router",
            opts.on_error
        )

        return false
    end


    local prompt = opts.prompt
    if type(prompt) ~= "string" or vim.trim(prompt) == "" then
        notify_warn(
            "Empty or missing prompt. Aborting dispatch.",
            "Ollie Router",
            opts.on_error
        )
        return false
    end

    local allowed, permission_err = permission.authorize_request({
        task = task,
        provider = provider_name,
        model = model,
        prompt = prompt,
    })

    if not allowed then
        notify_error(
            permission_err,
            "Ollie Security",
            opts.on_error
        )
        return false
    end


    local has_callbacks = type(opts.on_response) == "function"
        or type(opts.on_chunk) == "function"
        or type(opts.on_complete) == "function"

    if not has_callbacks then
        notify_error(
            "router.request(): at least one response callback is required"
            .. " (on_response, on_chunk, or on_complete).",
            "Ollie Router",
            opts.on_error
        )
        return false
    end


    local stream = opts.stream
    if stream == nil then
        stream = defaults.stream
    end


    local body = {
        model = model,
        prompt = prompt,
        stream = stream,
    }

    local callbacks = {
        on_response = opts.on_response,   -- non-streaming: full response at once
        on_chunk = opts.on_chunk,       -- streaming: called per chunk
        on_complete = opts.on_complete,    -- streaming: called when stream ends
        on_error = opts.on_error,       -- called on any provider-side error
    }

    local ok, stream_or_err = pcall(provider.generate, body, callbacks)
    if not ok then
        notify_error(tostring(stream_or_err), "Ollie Router", opts.on_error)
        return false
    end

    return stream_or_err
end


-- dynamic rule registration
function M.register_rule(task, rule)

    if type(task) ~= "string" or task == "" then
        vim.notify(
            "register_rule: task must be a non-empty string.",
            vim.log.levels.WARN,
            { title = "Ollie Router" }
        )
        return
    end


    if type(rule) ~= "table" then
        vim.notify(
            "register_rule: rule must be a table with 'provider' and 'model' keys.",
            vim.log.levels.WARN,
            { title = "Ollie Router" }
        )
        return
    end


    if type(rule.provider) ~= "string" or rule.provider == "" then
        vim.notify(
            "register_rule: rule.provider must be a non-empty string.",
            vim.log.levels.WARN,
            { title = "Ollie Router" }
        )
        return
    end


    if type(rule.model) ~= "string" or rule.model == "" then
        vim.notify(
            "register_rule: rule.model must be a non-empty string.",
            vim.log.levels.WARN,
            { title = "Ollie Router" }
        )
        return
    end

    rules[task] = rule
end


function M.setup(opts)
    opts = opts or {}

    -- Merge user-supplied rules over the static defaults
    if type(opts.rules) == "table" then
        for task, rule in pairs(opts.rules) do
            M.register_rule(task, rule)
        end
    end

    -- Merge user-supplied defaults
    if type(opts.defaults) == "table" then
        if opts.defaults.stream ~= nil then
            defaults.stream = opts.defaults.stream
        end
    end
end

-- retrieve routing table
function M.get_rules()
    return rules
end

return M
