local M = {}

function M.normalize(chunk)

    if not chunk then
        return ""
    end

    chunk = chunk:gsub("\r\n", "\n")
    chunk = chunk:gsub("\r", "\n")

    return chunk
end

return M