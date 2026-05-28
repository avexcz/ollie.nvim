local M = {}

local listeners = {}

function M.on(event, fn)
    listeners[event] = listeners[event] or {}
    table.insert(listeners[event], fn)
end

function M.emit(event, data)
    local subs = listeners[event]
    if not subs then return end

    for _, fn in ipairs(subs) do
        local ok, err = pcall(fn, data)
        if not ok then
            vim.notify(
                "Event error [" .. event .. "]: " .. tostring(err),
                vim.log.levels.ERROR,
                { title = "Ollie" }
            )
        end
    end
end

function M.clear()
    listeners = {}
end

return M