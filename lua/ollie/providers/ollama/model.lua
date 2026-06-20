local M = {}

-- load engines
local stream_engine = require("ollie.core.stream")
local chunks = require("ollie.parser.chunks")
local sanitise = require("ollie.parser.sanitise")
local bootstrap = require("ollie.providers.ollama.boostrap")

-- default config of ollama
local default_config = {
    host = "http://localhost:11434",
    timeout = 30000,
}

M.models = {
    "avexcoder_3b:latest",
    "qwen2.5-coder:1.5b",
    "qwen2.5-coder:3b",
    "llama3.2:latest",
}

M.config = vim.deepcopy(default_config) -- Ensure we have a mutable config table

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {}) -- Allow users to override defaults
end

-- Track active job
local active = {}

-- preferred notification
local function safe_notify(msg, level)
    vim.schedule(function()
        vim.notify(msg, level or vim.log.levels.INFO)
    end)
end

-- patch up
local function cleanup(buf, stream)
    if active[buf] == stream then
        active[buf] = nil
    end
    stream_engine.finish(stream)
end

-- cancel
function M.cancel(stream)
    if not stream then return end

    local buf = stream.buf
    if stream.job_id then
        pcall(vim.fn.jobstop, stream.job_id)
    end

    cleanup(buf, stream)
end

-- generate 
function M.generate(body, callbacks)
    callbacks = callbacks or {}

    if not bootstrap.ensure_running() then
        if type(callbacks.on_error) == "function" then
            callbacks.on_error({
                error = "Failed to start Ollama server"
            })
        end
        return
    end

    local buf = callbacks.buf or vim.api.nvim_create_buf(false, true)

    if active[buf] then
        M.cancel(active[buf])
    end

    local stream = stream_engine.start(buf)
    active[buf] = stream

    local accumulated = {}

    -- encode the json
    local encoded_body = vim.fn.json_encode({
        model = body.model,
        prompt = body.prompt,
        stream = (body.stream ~= false),
    })

    local url = M.config.host .. "/api/generate"

    -- run ollama asynchronously
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
        
        -- standard output
        on_stdout = function(_, data)
            for _, line in ipairs(data) do
                if line == "" then goto continue end

                -- decode the json
                local ok, decoded = pcall(vim.fn.json_decode, line)
                if not ok or type(decoded) ~= "table" then
                    goto continue
                end

                local s = active[buf]
                if s ~= stream then return end
                local text = decoded.response or decoded.text or ""
                if text ~= "" then
                    text = chunks.normalize(text)
                    text = sanitise.clean(text)
                    table.insert(accumulated, text)

                    if body.stream ~= false and type(callbacks.on_chunk) == "function" then
                        callbacks.on_chunk({ response = text })
                    end
                end

                if decoded.done then
                    local full_text = table.concat(accumulated, "")
                    if type(callbacks.on_response) == "function" then
                        callbacks.on_response({ output = full_text })
                    end
                    if type(callbacks.on_complete) == "function" then
                        callbacks.on_complete({ output = full_text })
                    end
                    cleanup(buf, stream)
                    return
                end

                ::continue::
            end
        end,

        -- standard error
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


        -- exit
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
        if type(callbacks.on_error) == "function" then
            callbacks.on_error({ error = "Failed to start curl job" })
        else
            safe_notify("Failed to start curl job", vim.log.levels.ERROR)
        end
        cleanup(buf, stream)
        return nil
    end

    stream.job_id = job_id
    stream.buf = buf

    return stream
end

return M
