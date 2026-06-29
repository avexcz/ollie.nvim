local M = {}

local state = {
    active = false,
    start_time = 0,
    events = {}
}

-- helper
local function current()
    return vim.uv.hrtime() / 1e6
end

-- start trace
function M.start()
    state.active = true
    state.start_time = now()
    state.events = {}
end

-- log event
function M.log(label)
    if not state.active then
        return
    end

    local elapsed = now() - state.start_time

    table.insert(state.events, {
        label = label,
        time = elapsed
    })

    print(string.format("[+%.2f ms] %s", elapsed, label))
end

-- end trace
function M.finish()
    state.active = false
end

return M
