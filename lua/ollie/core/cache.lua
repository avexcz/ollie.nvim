local M = {}

local data_path = vim.fn.stdpath("data") .. "/ollie/sessions"

-- ensure directory exists
local function ensure_dir()
    vim.fn.mkdir(data_path, "p")
end

-- session file path
local function session_path(id)
    return data_path .. "/" .. id .. ".json"
end

-- save session
function M.save(id, data)
    local ok = pcall(ensure_dir)
    if not ok then
        return false
    end

    local path = session_path(id)
    local encoded = vim.fn.json_encode(data)

    return pcall(vim.fn.writefile, { encoded }, path)
end

-- load session
function M.load(id)
    local path = session_path(id)

    if vim.fn.filereadable(path) == 0 then
        return nil
    end

    local lines = vim.fn.readfile(path)
    local content = table.concat(lines, "\n")

    return vim.fn.json_decode(content)
end

-- delete session
function M.delete(id)
    local path = session_path(id)

    if vim.fn.filereadable(path) == 1 then
        vim.fn.delete(path)
    end
end

-- list cached sessions
function M.list()
    local ok = pcall(ensure_dir)
    if not ok then
        return {}
    end

    local files = vim.fn.globpath(
        data_path,
        "*.json",
        false,
        true
    )

    local result = {}

    for _, file in ipairs(files) do

        local lines = vim.fn.readfile(file)
        local content = table.concat(lines, "\n")

        local ok, decoded = pcall(
            vim.fn.json_decode,
            content
        )

        if ok and decoded then
            table.insert(result, decoded)
        end
    end

    table.sort(result, function(a, b)
        return a.created_at > b.created_at
    end)

    return result
end

return M
