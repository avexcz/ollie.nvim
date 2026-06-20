local M = {}

function M.text(response)
    if type(response) == "table" then
        return response.output or response.response or response.content or ""
    end

    return tostring(response or "")
end

return M
