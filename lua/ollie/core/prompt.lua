local M = {}

local templates = {}

templates.chat = function(opts)
    return table.concat({
        "You are a helpful AI assistant.",
        "",
        "User:",
        opts.prompt or "",
        "",
        "Assistant:"
    }, "\n")
end

templates.fix = function(opts)
    return table.concat({
        "You are a senior software engineer.",
        "Fix the following code.",
        "Return ONLY the corrected code.",
        "",
        opts.code or opts.prompt or "",
    }, "\n")
end

templates.autocomplete = function(opts)
    return table.concat({
        "You are an intelligent code completion engine.",
        "Complete the code naturally.",
        "Do not explain anything.",
        "",
        opts.code or opts.prompt or "",
    }, "\n")
end

function M.build(task, opts)
    opts = opts or {}

    local template = templates[task]

    if not template then
        return opts.prompt or ""
    end

    return template(opts)
end

return M