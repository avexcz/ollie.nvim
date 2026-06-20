local M = {}

local chunks = require("ollie.parser.chunks")
local sanitise = require("ollie.parser.sanitise")

function M.process(text)
    text = chunks.normalize(text)
    text = sanitise.clean(text)

    return text
end

return M