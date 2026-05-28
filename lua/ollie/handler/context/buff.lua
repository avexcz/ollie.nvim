local M = {}

-- buffer content
local function get_buffer_content()
    local lines = vim.api.nvim_buf_get_lines( -- get the content of the current buffer as a list of lines
        0,
        0,
        -1,
        false
    )
    return table.concat(lines, "\n") -- join the list of lines into a single string with line breaks

--[[
    vim.api.nvim_buf_get_lines(bufnr, start, end, strict_indexing)
     0: current buffer
     0: start line (0-indexed)
    -1: end line (-1 means last line)
     false: don't include line breaks 
     ]]
end

--cursor position
local function get_cursor()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0)) -- get the current blinking cursor position as a tuple (line, column)

    return {
        line = line,
        col = col,
    }
end

-- file type
local function get_filetype()
    return vim.api.nvim_get_option_value("filetype", { buf = 0 }) -- get the file type of the current buffer (e.g., "lua", "python", etc.)
end


function M.get_context()
    local context = {
        buffer_content = get_buffer_content(), -- get the content of the current buffer as a list of lines
        cursor_position = get_cursor(), -- get the current blinking cursor position as a tuple (line, column)
        file_type = get_filetype(), -- get the file type of the current buffer (e.g., "lua", "python", etc.)

    }
    return context

end


return M