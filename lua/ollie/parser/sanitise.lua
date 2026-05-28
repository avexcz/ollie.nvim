local M = {}

function M.clean(chunk)
    if not chunk then
        return ""
    end

    -- remove null bytes
    chunk = chunk:gsub("%z", "")

    -- remove ANSI terminal colors
    chunk = chunk:gsub("\27%[[0-9;]*m", "")

    return chunk
end

return M