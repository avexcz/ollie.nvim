local M = {}

local function to_string(chunk)
    if chunk == nil then
        return ""
    end

    if type(chunk) == "string" then
        return chunk
    end

    if type(chunk) == "table" then
        if type(chunk.content) == "string" then
            return chunk.content
        end

        if type(chunk.delta) == "string" then
            return chunk.delta
        end

        if type(chunk.text) == "string" then
            return chunk.text
        end

        return vim.inspect(chunk)
    end

    return tostring(chunk)
end


function M.normalize(chunk)
    local text = to_string(chunk)

    if not text then
        return ""
    end

    text = text:gsub("\r\n", "\n") -- replace Windows line endings with UNIX line endings
    text = text:gsub("\r", "\n") -- replace any remaining carriage returns with newlines

    return text
end


return M