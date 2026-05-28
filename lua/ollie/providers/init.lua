local M = {}

--add a provider manager to manage multiple providers, allowing users to switch between them easily and configure them as needed. This manager can handle provider-specific settings, authentication, and fallback mechanisms.
-- provider registry + common interface

M.providers = {
    ollama = require("ollie.providers.ollama.model"),
    openai = require("ollie.providers.openai.cloud"),
    anthropic = require("ollie.providers.anthropic.cloud"),
    google = require("ollie.providers.google.cloud"),
}

function M.get(name)
    
    local provider = M.providers[name]

    if not provider then
        vim.notify(
            "Provider not found: " .. name,
            vim.log.levels.ERROR,
            { title = "Ollie" }
        )

        return nil
    end

    return provider
end





return M