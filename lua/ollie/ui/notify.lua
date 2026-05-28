local M = {}

function M.running(provider, model, task)
    vim.notify(
        string.format(
            "[%s] Running %s on %s",
            provider,
            task,
            model
        ),
        vim.log.levels.INFO,
        { title = "Ollie" }
    )
end

function M.switched(kind, value)
    vim.notify(
        string.format(
            "Switched %s -> %s",
            kind,
            value
        ),
        vim.log.levels.INFO,
        { title = "Ollie" }
    )
end

return M