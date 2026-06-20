--- task router for chat, debug, and explain

local M = {}

-- resolve mode and normalize options
local function resolve_mode(mode)
    return mode or "chat"
end

local function normalize_opts(opts)
    opts = opts or {}

    local normalized = vim.tbl_extend("force", {}, opts)
    normalized.include_context = opts.include_context == true

    return normalized
end

------------------------------------------
-- main dispatcher
------------------------------------------
function M.send(mode, text, opts)
    mode = resolve_mode(mode)
    opts = normalize_opts(opts)

    if (not text or vim.trim(text) == "") and mode ~= "chat" then
        return
    end

    if mode == "chat" then
        local chat = require("ollie.handler.chat")
        chat.run_chat(text, opts)
        return
    end

    if mode == "debug" then
        local debug = require("ollie.handler.debug")
        debug.run_fix(text, opts)
        return
    end

    if mode == "explain" then
        local explain = require("ollie.handler.explain")
        explain.run_explain(text, opts)
        return
    end

    vim.notify(
        "Unknown send mode: " .. tostring(mode),
        vim.log.levels.WARN
    )
end

----------------------------------------
-- convenience wrappers
----------------------------------------
function M.chat(text, opts)
    M.send("chat", text, opts)
end

function M.debug(text, opts)
    M.send("debug", text, opts)
end

function M.explain(text, opts)
    M.send("explain", text, opts)
end


return M
