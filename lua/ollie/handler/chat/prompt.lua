local M = {}

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

    -- no context mode 
    if not opts.include_context then
        return query
    end

    local buffer_content = ""

    local filetype = ""
    if type(opts.context) == "table" then
        buffer_content = opts.context.buffer_content or ""
        filetype = opts.context.filetype or ""
    end


    return table.concat({

        SYSTEM_PROMPT,
        "",
        "Context (" .. (filetype ~= "" and filetype or "unknown") .. "):",
        "```" .. filetype,
        buffer_content,
        "```",
        "",
        "User Request:",
        query,
        
    }, "\n")
end

return M
