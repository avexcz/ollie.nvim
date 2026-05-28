local M = {}

local panel = require("ollie.ui.panel")
local float = require("ollie.ui.front")

local augroup = vim.api.nvim_create_augroup("OllieResize", { clear = true })

local resize_timer = nil
local debounce_ms = 80

local function schedule_resize(fn)
    if resize_timer then
        resize_timer:stop()
        resize_timer:close()
    end

    resize_timer = vim.loop.new_timer()
    resize_timer:start(
        debounce_ms,
        0,
        vim.schedule_wrap(function()
            fn()
        end)
    )
end

local function do_resize()
    -- panel resize
    local panel_win = panel.get_win()
    if panel_win and vim.api.nvim_win_is_valid(panel_win) then
        panel.resize()
    end

    -- float resize
    local float_win = float.get_win()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
        float.resize()
    end
end

function M.setup()
    vim.api.nvim_create_autocmd("VimResized", {
        group = augroup,
        callback = function()
            schedule_resize(do_resize)
        end,
    })
end

function M.teardown()
    vim.api.nvim_clear_autocmds({ group = augroup })

    if resize_timer then
        resize_timer:stop()
        resize_timer:close()
        resize_timer = nil
    end
end

return M