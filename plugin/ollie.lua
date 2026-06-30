function M.setup(opts)
    require("ollie.config").setup(opts)

    local g = vim.api.nvim_create_augroup('ollie', { clear = true })

    vim.api.nvim_create_autocmd('VimEnter', {
        group = g,
        callback = function()
            for _, v in ipairs(vim.v.argv) do
                if v == '-' then
                    vim.g.read_from_stdin = 1
                    break
                end
            end
        end,
    })
end
