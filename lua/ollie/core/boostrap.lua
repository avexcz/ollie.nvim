local events = require("ollie.core.events")
local session = require("ollie.core.session")

local panel = require("ollie.ui.panel")
local render = require("ollie.ui.render")

local M = {}

local function normalize(msg)
    if type(msg) == "table" then
        return msg.content or ""
    end
    return msg
end

function M.init()

    -- session wiring
    events.on("user_message", function(msg)
        local s = session.get_active()
        if not s then return end

        table.insert(s.messages, {
            role = "user",
            content = normalize(msg),
        })
    end)

    events.on("assistant_message", function(msg)
        local s = session.get_active()
        if not s then return end

        table.insert(s.messages, {
            role = "assistant",
            content = normalize(msg),
        })
    end)


    -- UI wiring
    events.on("task_start", function(data)
        if data.task ~= "fix" then return end
        panel.open()
    end)

    events.on("stream_chunk", function(data)
        if data.task ~= "fix" then return end
        panel.append(data.text)
    end)

    events.on("task_complete", function(data)
        if data.task ~= "fix" then return end
        panel.finish()
    end)

    events.on("task_error", function(data)
        render.error(data.error)
    end)

end

return M