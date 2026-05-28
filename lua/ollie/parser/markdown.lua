local M = {}

-- parse a fully assembled markdown line
function M.parse(line)

    if not line or line == "" then
        return {
            type = "empty",
            value = line,
        }
    end

    -- fenced codeblock
    local language = line:match("^```(%w+)") -- ```

    if line:match("^```") then
        return {
            type = "codeblock",
            language = language or "",
            value = line,
        }
    end

    -- markdown heading
    local hashes, text = line:match("^(#+)%s(.+)$") -- # 

    if hashes then
        return {
            type = "heading",
            level = #hashes,
            value = text,
        }
    end

    -- unordered list
    local item = line:match("^[-*+]%s(.+)$") -- - or * or +

    if item then
        return {
            type = "list",
            value = item,
        }
    end

    -- blockquote
    local quote = line:match("^>%s(.+)$") -- >

    if quote then
        return {
            type = "blockquote",
            value = quote,
        }
    end

    -- inline code
    if line:match("`.-`") then
        return {
            type = "inline_code",
            value = line,
        }
    end

    -- normal paragraph/text
    return {
        type = "text",
        value = line,
    }
end

return M