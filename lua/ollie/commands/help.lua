local M = {}

-- render's components
local state = {
    buf = nil,
    win = nil,
}

-- content section
local sections = {
    { title = "1. documentation", file = "documentation.md" },
    { title = "2. command lines", file = "command.md" },
    { title = "3. configuration", file = "configuration.md" },
    { title = "4. contributing",  file = "CONTRIBUTING.md"},
    { title = "5. architecture",  file = "ARCHITECTURE.md"}
}

-- private API function of documentation directory
local function docs_dir()
    local source = debug.getinfo(1, "S").source
    local file = source:sub(1, 1) == "@" and source:sub(2) or source
    local root = vim.fn.fnamemodify(file, ":p:h:h:h:h")

    return root .. "/docs"
end

-- private API function which read the documentation
local function read_doc(path)
    if vim.fn.filereadable(path) == 0 then
        return {
            "Missing documentation file: " .. path,
        }
    end

    return vim.fn.readfile(path)
end

-- private API function which format the documentation
local function build_lines()
    local dir = docs_dir()
    local lines = {
        "# Ollie Help",
        "",
        "1. documentation ",
        "2. command lines ",
        "3. configuration ",
        "4. contribution  ",
        "5. architecture  ",
        "",
    }

    -- documentation's format
    for _, section in ipairs(sections) do
        vim.list_extend(lines, {
            "--------------------------------------------------------------------------------",
            "",
            "## " .. section.title,
            "",
        })

        vim.list_extend(lines, read_doc(dir .. "/" .. section.file))
        table.insert(lines, "")
    end

    return lines
end

-- private API function which close the window buffer 
local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    state.win = nil
end

-- private API function which command ollie to display window
local function open_window()
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)
    end

    -- width and height of the current rendering window
    local width = math.floor(vim.o.columns * 0.7)
    local height = math.floor(vim.o.lines * 0.75)

    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end

    -- window UI design
    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Ollie Help ",
        title_pos = "center",
    })

    -- window UI formatter
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, build_lines())
    vim.bo[state.buf].modifiable = false
    vim.bo[state.buf].readonly = true
    vim.bo[state.buf].filetype = "markdown"
    vim.bo[state.buf].bufhidden = "wipe"

    -- vim keymap of quit and esc to close
    vim.keymap.set("n", "q", close, { buffer = state.buf, silent = true })
    vim.keymap.set("n", "<Esc>", close, { buffer = state.buf, silent = true })
end


--------------------------------------
-- :OllieHelp
--------------------------------------
local function create_help_command()
    vim.api.nvim_create_user_command("OllieHelp", function()
        open_window()
    end, {})
end

-- Public API setup function
function M.setup()
    create_help_command()
end

return M
