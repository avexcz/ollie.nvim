-- dead file
local M = {}


function M.user(content, msg_type)
    return {
        role = "user",
        type = msg_type or "chat",
        content = content,
        timestamp = os.time(),
    }
end

function M.assistant(content, msg_type)
    return {
        role = "assistant",
        type = msg_type or "chat",
        content = content,
        timestamp = os.time(),
    }
end

return M 
