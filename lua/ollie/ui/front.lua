local M = {}
-- work on send button, ui box, blur background, model switching and loading animation
function M.open(content)
    local buf = vim.api.nvim_create_buf(false, true) -- listed, scratch buffer
    local lines = vim.split(content, "\n")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local width = math.floor(vim.o.columns * 0.6)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = "Ollie AI",
        title_pos = "center",
    })

    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<CR>", { noremap = true, silent = true }) -- Press 'q' to close

end

return M