local M = {}

local context = require("ollie.handler.context.buff")

-----------------
-- system prompt
-----------------

local SYSTEM_PROMPT = table.concat({

    "You are working inside a Neovim editor. Please answer the user's question based on the provided context.",
    "If the context is not relevant, rely on your general programming knowledge.",
}, "\n")

----------------
-- build prompt
----------------

function M.build(query, opts)

    opts = opts or {}
    local include_context = opts.include_context

    -- no context mode
    if not include_context then
        return query
    end

    local ctx = context.get_context() or {}

    return table.concat({

        SYSTEM_PROMPT,
        "",
        "User Request:",
        query,
        "",
        "File Type:",
        ctx.file_type or "",
        "",
        "Buffer Content:",
        "```" .. (ctx.file_type or ""),
        ctx.buffer_content or "",
        "```",

    }, "\n")
end

return M