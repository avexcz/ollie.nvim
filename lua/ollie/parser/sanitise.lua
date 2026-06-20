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

function M.clean(chunk)
    local text_string = to_string(chunk)

    if text_string == nil or text_string == "" then
        return ""
    end

    -- remove null bytes
    text_string = text_string:gsub("%z", "")

    -- remove ANSI terminal colors
    text_string = text_string:gsub("\27%[[0-9;]*m", "")

    return text_string
end

return M