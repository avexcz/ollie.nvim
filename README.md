 # Ollie
`ollie.nvim` is a Neovim plugin that integrates any model capabilities directly into the editor, default model is `avexcoder_3b:latest`.  It is designed around a clean separation of concerns: providers handle model communication, security, permissions, handlers define task semantics, and the UI layer stays thin and replaceable. The goal is a plugin you can trust, extend, and run entirely on low-end till high-end devices. Its router dispatches requests asynchronously across providers and experimental hardware-aware routing — so you run the best model your environment can actually support.


<br>

### Features
 
- **Multi-provider support** — Anthropic (Claude API + CLI), OpenAI (Cloud + Codex CLI), Google (Cloud + local), Ollama (local inference). Switch providers per task.
- **Structured handlers** — Discrete commands for explanation, debugging, fixing, refactoring, and completion. Each handler owns its context and prompt logic independently.
- **Streaming responses** — Streaming incremental responses. No waiting for full completions.
- **Async job architecture** — All I/O runs off the main thread via Neovim's `vim.loop` / `vim.jobstart`. The editor never blocks.
- **Buffer context management** — Smart context assembly from the active buffer, visual selection, LSP diagnostics, and file metadata.
- **Health system** — Built-in `:checkhealth ollie` covering hardware capability, internet reachability, model availability, and Ollama process status.
- **Security layer** — Permission model, policy enforcement, and trust management for sensitive operations.
- **Selector abstraction** — Picker-agnostic model and provider selection. Works with `telescope.nvim`, `fzf-lua`, `vim.ui.select`, or custom frontends.



<br>
 
### Architecture
```
┌─────────────────────────────────────────────┐
│                   UI Layer                  │  Split panes, inline virtual text, float windows
├─────────────────────────────────────────────┤
│              Selector Layer                 │  Model / session / context picker
├──────────────────┬──────────────────────────┤
│ Context Manager  │      Handler Registry    │  Buffer ctx │ Stream, diff, replace
├──────────────────┴──────────────────────────┤
│              Streaming Engine               │  Chunked SSE parsing, backpressure
├─────────────────────────────────────────────┤
│               Async Job Layer               │  vim.jobstart
├─────────────────────────────────────────────┤
│              Provider Adapters              │  OpenAI · Anthropic · Ollama · custom
└─────────────────────────────────────────────┘
```


(ARCHITECTURE FOLDER TREE HERE)

```
ollie.nvim
├── providers/        # API clients for each LLM backend (cloud, local, CLI)
├── handler/          # Task logic: explain, fix, refactor, debug, complete
│   └── context/      # Buffer and workspace context assembly
├── core/
│   ├── router.lua    # Dispatches requests to the correct provider+handler pair
│   └── selector.lua  # Abstraction layer over picker UI
├── ui/               # Panel and floating window rendering
├── system/
│   ├── health/       # Environment diagnostics
│   └── security/     # Permissions, policies, trust
├── commands/         # User-facing command definitions
└── autocmd/          # Editor event hooks
```

Design principles:

- Providers are stateless adapters. They translate requests to API shapes and return a stream or a string. They know nothing about Neovim buffers.
- Handlers are stateless functions. They assemble context, call a provider via the router, and write output. They know nothing about which provider is active.
- The router is the only component that knows both sides. Swapping a provider never touches handler code.
- The UI layer is purely presentational. It receives text and renders it. No business logic lives there.
- The health system is a first-class citizen, not an afterthought. If something is misconfigured, `:checkhealth ollie` should tell you exactly what and why.


<br>

### Installation
Requirements:
1. Neovim >= 0.10
2. curl (for HTTP providers)

<u><b>lazy.nvim</b></u> 
<br>

```lua
lua{
  "avexcz/ollie.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- optional, for selector layer
    "nvim-telescope/telescope.nvim",
  },
  opts = {},
}
```

<b><u>packer.nvim</u></b>
<br>

```lua
luause {
  "avexcz/ollie.nvim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("nvim-ai").setup({})
  end
}
```
<br>

### Configuration

```lua
require("ollie").setup({
 
 providers = {
    
    openai = {
      api_key = vim.env.OPENAI_API_KEY,
      base_url = "https://api.openai.com/v1",
      model = "gpt-4o",
      max_tokens = 4096,
    },
    
    anthropic = {
      api_key = vim.env.ANTHROPIC_API_KEY,
      base_url = "https://api.anthropic.com/v1",
      model = "claude-opus-4-5",
      max_tokens = 8192,
    },
    ollama = {
      base_url = "http://localhost:11434",
      model = "llama3",
    },
 
 }
})
```

<br>

| Command | Description |
|---|---|
| `Ollie` | Open the dashboard that have settings. |
| `:OllieChat` | Open the chat interface with the active provider |
| `:OllieCHAT` | Send the whole buffer and open the chat interface with the active provider |
| `:OllieEdit` | Rewrite the current visual selection |
| `:OllieDebug` | Analyse the current buffer and diagnostics for bugs |
| `:OllieAnalyse` | Open the context picker and select any file to analyse |
| `:OllieANALYSE` | Analyse all files in a folder and Open the context picker to get response |
| `:OllieFix` | Diagnose and apply a fix for the current error or selection |
| `:OllieModel` | Switch the active model via selector |
| `:OllieProvider` | Switch the active provider via selector |
| `:OllieAbort` | Abort the in-flight request |
| `:OllieHistory` | Browse and resume previous sessions |
| `:checkhealth ollie` | Validate providers, credentials, hardware health, recommanded model and dependencies |

<br>

### Contributing
 
Contributions are welcome. Before opening a PR, please read the following.
 
**Project conventions:**
- Lua files follow the existing module structure. New functionality belongs in an appropriate layer — provider logic in `providers/`, user-facing operations in `handler/`, rendering in `ui/`.
- No business logic in the UI layer. No Neovim API calls in providers.
- All async operations use `vim.loop` or `vim.system`. No blocking I/O on the main thread.
- New providers must implement the provider interface defined in `providers/init.lua`.
- New handlers must be reachable via the router and must not hardcode a provider.

<br>

See [documentation](./documementation.md) for more info. <br>
See [user guide](./help.md) for tutorial or user guidance. <br>
See [List of commands](./command.md) for understanding how to use commands. <br>

---
 
<sub>Built for Neovim. Runs anywhere a Lua runtime and an HTTP connection (or local model) can reach.</sub>
