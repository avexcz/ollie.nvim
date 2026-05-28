local M = {}

local events = require("ollie.core.events")

local sessions = {}
local active = nil

----------------
-- start session
----------------
function M.start(mode)
    local id = tostring(vim.loop.hrtime()) .. "-" .. tostring(math.random(1000,9999))

    sessions[id] = {
        id = id,
        mode = mode,
        messages = {},
        created_at = os.time(),
    }

    active = id
    return id
end

-----------------
-- active session
-----------------
function M.get_active()
    return active and sessions[active] or nil
end

--------
-- list sessions
--------
function M.list()
    return sessions
end

-----------
-- history
-----------
function M.get_history(id)
    id = id or active
    if not id or not sessions[id] then return {} end
    return sessions[id].messages
end

-------------------
-- switch session
-------------------
function M.switch(id)
    if not sessions[id] then
        vim.notify("Invalid session: " .. tostring(id))
        return
    end

    active = id
    events.emit("session_switched", id)
end

-------------------
-- delete session
-------------------
function M.delete(id)
    id = id or active
    if not id or not sessions[id] then return end

    sessions[id] = nil

    if active == id then
        active = nil

        -- fallback
        for k, _ in pairs(sessions) do
            active = k
            break
        end

        events.emit("session_closed", id)
    end
end

-------------
-- clear all
-------------
function M.clear()
    sessions = {}
    active = nil
    events.emit("sessions_cleared")
end

---------------------------
-- message persistence
---------------------------
events.on("user_message", function(msg)
    local s = M.get_active()
    if not s then return end

    table.insert(s.messages, {
        role = "user",
        content = msg,
    })
end)

events.on("assistant_message", function(msg)
    local s = M.get_active()
    if not s then return end

    table.insert(s.messages, {
        role = "assistant",
        content = msg,
    })
end)

return M