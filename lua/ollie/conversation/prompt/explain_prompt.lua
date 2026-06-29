local M = {}

local ft = vim.bo[0].filetype

-- fix prompt
function M.explain(query, selected_code)

    return table.concat({
        "You are an expert programmer.",
        "Explain the given code based on the user's instruction.",
        "Explain the code clearly and technically.",
        "Focus on logic, flow, and important concepts.",
        "Do not rewrite the code unless necessary.",
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