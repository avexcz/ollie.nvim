local M = {}

--[[
1. functions
1.1 get_selected_code()

]]


function M.get_selected_code()
    local start_pos = vim.fn.getpos("'<") -- get the position of the start of the visual selection as a tuple (line, column)
    local end_pos = vim.fn.getpos("'>") -- get the position of the end of the visual selection as a tuple (line, column)

    local start_line = start_pos[2] -- get the line number of the start of the visual selection
    local start_col = start_pos[3] -- get the column number of the start of the visual selection

    local end_line = end_pos[2] -- get the line number of the end of the visual selection
    local end_col = end_pos[3] -- get the column number of the end of the visual selection

    local lines = vim.api.nvim_buf_get_lines(
        0,
        start_line - 1,
        end_line,
        false
    )

    if #lines == 0 then
        return nil
    end

    -- trim first line
    lines[1] = string.sub(lines[1], start_col)

    -- trim last line
    lines[#lines] = string.sub(lines[#lines], 1, end_col)

    return table.concat(lines, "\n")
end




return M