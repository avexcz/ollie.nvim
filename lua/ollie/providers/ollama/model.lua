local M = {}
-- work on "If sufficient RAm then use qwen2.5-coder:3b/mid/high else use cloud AI " on health check of the system, also add a check to see if ollama server is running or not and if not then fallback to cloud AI (maybe gpt4all or something)

local host = "http://localhost:11434"

function M.generate(model, prompt, callback)

    local body = vim.json.encode({
        model = model,
        prompt = prompt,
        stream = false,
    })

    vim.system({
        "curl",
        "-s",
        "-X", "POST",
        host .. "/api/generate",
        "-H",
        "Content-Type: application/json",
        "-d",
        body,
    }, {}, function(res)

        -- ollama offline
        if not res.stdout or res.stdout == "" then
            vim.schedule(function()
                vim.notify(
                    "Ollama server is not running",
                    vim.log.levels.ERROR,
                    { title = "Ollie" }
                )
            end)

            callback("Ollama offline")
            return
        end

        -- decode json
        local ok, data = pcall(vim.json.decode, res.stdout)

        if not ok then
            callback("JSON decode failed")
            return
        end

        -- api returned error
        if data.error then
            callback("Ollama error: " .. data.error)
            return
        end

        -- missing response
        if not data.response then
            callback("No response field found")
            return
        end

        -- success
        callback(data.response)

    end)
end

return M
