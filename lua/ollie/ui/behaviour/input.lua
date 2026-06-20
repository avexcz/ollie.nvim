local M = {}

local state = {
    processing = false,
}

-- internal helper
local function set_processing(value)
    state.processing = value
end

function M.is_processing()
    return state.processing
end

function M.ready(send_fn, on_sent)
    set_processing(false)

    vim.schedule(function()
        M.ask(send_fn, on_sent)
    end)
end

function M.finish()
    state.processing = false
end

function M.ask(send_fn, on_sent)
    vim.ui.input({
        prompt = "🤖 Ollie: ",
        completion = "file",
    }, function(text)

        -- user cancelled
        if text == nil then
            return
        end

        text = vim.trim(text)

        if text == "" then
            vim.notify(
                "Empty input. Please enter a query.",
                vim.log.levels.WARN,
                { title = "Ollie" }
            )

            vim.schedule(function()
                M.ask(send_fn, on_sent)
            end)

            return
        end

        if state.processing then
            vim.notify(
                "Previous message still processing...",
                vim.log.levels.WARN,
                { title = "Ollie" }
            )

            return
        end

        set_processing(true)

        local ok, err = pcall(function()

            if send_fn then
                send_fn(text)
            end

            if on_sent then
                on_sent(text)
            end

        end)

        if not ok then
            set_processing(false)

            vim.notify(
                err,
                vim.log.levels.ERROR,
                { title = "Ollie" }
            )
        end
    end)
end

function M.attach(buf, send_fn, on_sent)

    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    local function open_dialog()

        if state.processing then
            vim.notify(
                "Previous message still processing...",
                vim.log.levels.WARN,
                { title = "Ollie" }
            )
            return
        end

        M.ask(send_fn, on_sent)
    end

    vim.keymap.set(
        "n",
        "<CR>",
        open_dialog,
        {
            buffer = buf,
            noremap = true,
            silent = true,
            desc = "Ask Ollie",
        }
    )

    vim.keymap.set(
        "n",
        "a",
        open_dialog,
        {
            buffer = buf,
            noremap = true,
            silent = true,
            desc = "Ask Ollie",
        }
    )
end

return M