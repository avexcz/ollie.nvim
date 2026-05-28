local M = {}

local debug = require("ollie.handler.debug")
local session = require("ollie.core.session")
local events = require("ollie.core.events")

local RENDER = {
    PANEL = "panel",
}

local function create_fix_command()

    vim.api.nvim_create_user_command(
        "OllieFix",
        function(opts)

            session.start("fix")

            local lines = vim.api.nvim_buf_get_lines(
                0,
                opts.line1 - 1,
                opts.line2,
                false
            )

            local selected_code = table.concat(lines, "\n")

            events.emit("user_message", {
                role = "user",
                content = opts.args or "",
            })

            debug.run_fix(
                opts.args or "",
                selected_code,
                {
                    render = RENDER.PANEL,
                }
            )
        end,
        {
            nargs = "*",
            range = true,
        }
    )
end

function M.setup(opts)
    create_fix_command()
end

return M