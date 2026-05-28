local M = {}

local stream_engine = require("ollie.core.stream")
local ui = require("ollie.ui.front")
local chunks = require("ollie.parser.chunks")
local sanitise = require("ollie.parser.sanitise")
local markdown = require("ollie.parser.markdown")

local default_config = {
    host = "http://localhost:11434",
    timeout = 30000,
}

M.config = vim.deepcopy(default_config) -- Ensure we have a mutable config table

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {}) -- Allow users to override defaults
end

-- Track active jobs: bufnr -> stream
local active = {}

local function safe_notify(msg, level)
    vim.schedule(function()
        vim.notify(msg, level or vim.log.levels.INFO)
    end)
end

local function cleanup(buf, stream)
    if active[buf] == stream then
        active[buf] = nil
    end
    stream_engine.finish(stream)
end

function M.cancel(stream)
    if not stream then return end

    local buf = stream.buf
    if stream.job_id then
        pcall(vim.fn.jobstop, stream.job_id)
    end

    cleanup(buf, stream)
end

function M.generate(body, callbacks)
    callbacks = callbacks or {}

    local buf = callbacks.buf or vim.api.nvim_create_buf(false, true)

    if active[buf] then
        M.cancel(active[buf])
    end

    local stream = stream_engine.start(buf)
    active[buf] = stream

    local accumulated = {}

    local encoded_body = vim.fn.json_encode({
        model = body.model,
        prompt = body.prompt,
        stream = (body.stream ~= false),
    })

    local url = M.config.host .. "/api/generate"

    local job_id = vim.fn.jobstart({
        "curl",
         "-sS",
         "-N",
         "-X",
         "POST",
        url,
        "-H", "Content-Type: application/json",
        "-d", encoded_body,
    }, {
        stdout_buffered = false,

        on_stdout = function(_, data)
            for _, line in ipairs(data) do
                if line == "" then goto continue end

                local ok, decoded = pcall(vim.fn.json_decode, line)
                if not ok or type(decoded) ~= "table" then
                    goto continue
                end

                local s = active[buf]
                if s ~= stream then return end
                if decoded.done then
                    local full_text = table.concat(accumulated, "")
                    if type(callbacks.on_complete) == "function" then
                        callbacks.on_complete({ output = full_text })
                    end
                    cleanup(buf, stream)
                    return
                end
                
                local text = decoded.response or decoded.text or ""
                if text ~= "" then
                    text = chunks.normalize(text)
                    text = sanitise.clean(text)

                    table.insert(accumulated, text)

                    if type(callbacks.on_chunk) == "function" then
                        callbacks.on_chunk({ response = text })
                    end
                end

                ::continue::
            end
        end,


        on_stderr = function(_, data)
            for _, line in ipairs(data) do
                if line ~= "" then
                    if type(callbacks.on_error) == "function" then
                        callbacks.on_error({ error = "Ollama: " .. line })
                    else
                        safe_notify(
                            "Ollie: " .. line,
                             vim.log.levels.ERROR)
                    end
                end
            end
        end,


        on_exit = function(_, code)
            local s = active[buf]
            if not s then return end

            if code ~= 0 then
                if type(callbacks.on_error) == "function" then
                    callbacks.on_error({
                        error = "curl exited with code: " .. tostring(code)
                    })
                else
                    safe_notify(
                        "curl exited with code: " .. code,
                        vim.log.levels.WARN
                    )
                end
            end

            cleanup(buf, stream)
        end,
    })

    if job_id <= 0 then
        safe_notify("Failed to start curl job", vim.log.levels.ERROR)
        cleanup(buf, stream)
        return nil
    end

    stream.job_id = job_id
    stream.buf = buf

    return stream
end

return M