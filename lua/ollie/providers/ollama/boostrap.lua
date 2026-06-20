-- responsible for running the ollama server if it is not already running
local M = {}

-- check if it's running or not
local function is_running()
    local result = vim.fn.system({
        "curl",
        "-s",
        "http://localhost:11434/api/tags"
    })

    return vim.v.shell_error == 0
end

-- make sure that ollama is actually running in order to start sending request
function M.ensure_running()
    
    if is_running() then
        return true
    end

    vim.fn.jobstart(
        { "ollama", "serve" },
        { detach = true, }
    )

    local start = vim.loop.now()

    -- repeat "curl -s http://localhost:11434/api/tags" every after 5 secs until it becomes true.
    while vim.loop.now() - start < 5000 do
        if is_running() then
            return true
        end

        vim.wait(200)
    end

    return false

end

return M