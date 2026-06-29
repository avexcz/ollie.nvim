local M = {}

local debug = require("ollie.handler.debug")
local explain = require("ollie.handler.explain")
local session = require("ollie.core.session")
local task = require("ollie.router.task")
local RENDER = {
    PANEL = "panel",
}

--------------------------------------
-- Helpers
--------------------------------------
local function get_selected_code(opts)
    local lines = vim.api.nvim_buf_get_lines(
        0,
        opts.line1 - 1,
        opts.line2,
        false
    )

    return table.concat(lines, "\n")
end


-------------------------------
-- :OllieFix
-------------------------------
local function create_fix_command()

    vim.api.nvim_create_user_command(
        "OllieFix",
        function(opts)

            -- session lifecycle
            session.start("fix")

            -- selected code
            local selected_code = get_selected_code(opts)
            
            -- execute debug handler
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

-------------------------------
-- :OllieExplain
-------------------------------
local function create_explain_command()
    vim.api.nvim_create_user_command(
    "OllieExplain",

    function(opts)

        -- session lifecycle
        session.start("explain")

        local selected_code = get_selected_code(opts)

        -- execute explain handler
        explain.run_explain(
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


-- setup
function M.setup(opts)
    create_fix_command()
    create_explain_command()
end

return M
