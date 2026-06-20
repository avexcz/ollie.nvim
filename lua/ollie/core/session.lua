local M = {}

-- load logs
local cache = require("ollie.core.cache")

-- call session table
local sessions = {}
local active = nil

-- generate random id (1000 - 9999)
local function generate_id()
    return tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
end

-- local backend engine for message count
local function message_count(messages)
    if type(messages) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(messages) do
        count = count + 1
    end

    return count
end

-- start session public API 
function M.start(mode)
    local id = generate_id()

    local data = {
        id = id,
        mode = mode or "chat",
        messages = {},
        created_at = os.time(),
        window = { buf = nil, win = nil },
    }

    sessions[id] = data
    active = id
    cache.save(id, data)

    return id
end

-- detection engine
function M.get_active()
    if not active then return nil end
    return sessions[active]
end

-- tell session to get id
function M.get(id)
    id = id or active
    if not id then return nil end

    if sessions[id] then
        return sessions[id]
    end

    local loaded = cache.load(id)
    if loaded then
        sessions[id] = loaded
        loaded.window = loaded.window or { buf = nil, win = nil }
        return loaded
    end

    return nil
end

function M.current()
    return active
end

function M.add(role, content)
    local current = M.get_active()
    if not current then return end

    table.insert(current.messages, {
        role = role,
        content = content,
        timestamp = os.time(),
    })

    cache.save(current.id, current)
end

-- list chat history
function M.list()
    local result = {}
    local seen = {}

    -- first add cached sessions
    local cached = cache.list()
    for _, s in ipairs(cached) do
        result[s.id] = s
        seen[s.id] = true
    end

    -- then add/override with in-memory sessions
    for id, s in pairs(sessions) do
        result[id] = s
        seen[id] = true
    end

    -- convert to list format for backwards compatibility
    local list = {}
    for _, s in pairs(result) do
        table.insert(list, {
            id = s.id,
            mode = s.mode,
            created_at = s.created_at,
            message_count = message_count(s.messages),
            active = (s.id == active),
        })
    end

    return list
end

-- public API for switch function
function M.switch(id)
    if M.get(id) then
        active = id
        return
    end
end

-- public API for delete function
function M.delete(id)
    id = id or active
    if not id then return end

    sessions[id] = nil
    cache.delete(id)

    if active == id then
        active = nil
    end
end

-- public API for close buffer content
function M.close()
    active = nil
end

-- public api for clear history content
function M.clear()
    local all = cache.list()
    for _, s in ipairs(all) do
        cache.delete(s.id)
    end
    sessions = {}
    active = nil
end

function M.set_window(buf, win)
    local s = M.get_active()
    if not s then return end

    s.window = s.window or {}
    s.window.buf = buf
    s.window.win = win
end

function M.get_window()
    local s = M.get_active()
    if not s then return end
    return s.window
end


return M
