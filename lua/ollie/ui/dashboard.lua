local M = {}


function M.create()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {""})
    vim.bo[buf].bufhidden = "wipe" --prevents memory leak
    vim.bo[buf].swapfile = false -- no swaping
    vim.bo[buf].filetype = "markdown" --file type
    vim.bo[buf].modifiable = true -- edit 

    return buf
end


function M.open(buf)
    local width = math.floor(vim.o.columns * 0.10)
    local height = math.floor(vim.o.lines * 0.10)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

   local win = vim.api.nvim_open_win(buf, true, {

        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,

        style = "minimal",
        border = "rounded",

        title = "Ollie Dashboard",
        title_pos = "center",
    })


    vim.api.nvim_buf_set_keymap(
        buf,
        "n",
        "q",
        "<cmd>bd!<CR>",
        { noremap = true, silent = true }
    )
    
    return win
end




return M