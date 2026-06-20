local M = {}

-- parsers
local parsers = require("ollie.parser.init")

-------------------------------
-- text normalization pipeline
-------------------------------
function M.process(text)
    return parsers.process(text)
end

-- normalize chunk
local function normalize(chunk)
    if type(chunk) == "table" then
        return chunk.response or chunk.text or chunk.content or ""
    end
    return tostring(chunk or "")
end

local separator = "------------------------------"

function M.user(text)
    text = M.process(text)

    return table.concat({
        "",
        "User:",
        separator,
        text or "",
        "",
    }, "\n")
end

function M.ollie_start()
    return table.concat({
        "Ollie:",
        separator,
    }, "\n")
end

function M.ollie(response, model)
    local text = normalize(response)
    text = M.process(text)

    local lines = {
        "Ollie:",
        separator,
        text or "",
    }

    if model and model ~= "" then
        vim.list_extend(lines, {
            "",
            "Model: " .. model,
        })
    end

    table.insert(lines, "")

    return table.concat(lines, "\n")
end

function M.ollie_end(model)
    if not model or model == "" then
        return ""
    end

    return table.concat({
        "",
        "Model: " .. model,
        "",
    }, "\n")
end


--query block format
function M.format_query(query, selected_code)
    query = M.process(query)
    selected_code = selected_code and M.process(selected_code) or nil

    local lines = {
        "",
        "User:",
        separator,
        query or "",
    }

    if selected_code and selected_code ~= "" then
        vim.list_extend(lines, {
            "",
            "Selected Code:",
            separator,
            selected_code,
        })
    end

    vim.list_extend(lines, {
        "",
        "Ollie:",
        separator,
        "",
    })

    return table.concat(lines, "\n")
end


-- chunk format
function M.chunk(chunk)

    local text = normalize(chunk)
    text = M.process(text)

    return text
end

-- completion format
function M.complete(response, model)
    return M.ollie(response, model)
end

-- error rendering
function M.error(err)

    return table.concat({
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "Error:",
        tostring(err),
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    }, "\n")
end

return M
