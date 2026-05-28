local M = {}


-- ui backends
local float = require("ollie.ui.front")
local panel = require("ollie.ui.panel")
local stream = require("ollie.ui.behaviour.stream")


-- render modes
local MODES = {
    CHAT = "chat",
    PANEL = "panel",
}


-- validate mode
local function is_valid_mode(mode)

    return mode == MODES.CHAT
    or mode == MODES.PANEL

end


-- chunk rendering
function M.chunk(mode, chunk)

    local text = type(chunk) == "table" and (chunk.response or chunk.text or "") or chunk
    if type(text) ~= "string" or text == "" then
        return
    end


    -- floating chat renderer
    if mode == MODES.CHAT then
        stream.append(float.get_buf(), float.get_win(), text)
        return
    end


    -- panel renderer
    if mode == MODES.PANEL then
        stream.append(panel.get_buf(), panel.get_win(), text)
        return
    end
end


-- completion rendering
function M.complete(mode, response)

    -- floating chat renderer
    if mode == MODES.CHAT then
        stream.finish(float.get_buf(), float.get_win())
        return
    end

    -- panel renderer
    if mode == MODES.PANEL then
        stream.finish(panel.get_buf(), panel.get_win())
        return
    end
end


-- error rendering
function M.error(err)
    local msg = type(err) == "table"
        and (err.error or err.message or vim.inspect(err))
        or tostring(err)
        
    vim.notify(
        msg,
        vim.log.levels.ERROR,
        { title = "Ollie" }
    )
end

return M