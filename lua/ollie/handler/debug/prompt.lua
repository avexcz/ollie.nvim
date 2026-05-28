local M = {}

local ft = vim.bo.filetype

-- fix prompt
function M.fix(query, selected_code)

    return table.concat({
        "You are an expert programmer.",
        "Fix the provided code strictly based on the user's instruction.",
        "Return only corrected code.",
        "",
        "Instruction:",
        query,
        "",
        "Code:",
        "```" .. ft,
        selected_code,
        "```",
    }, "\n")
end

return M