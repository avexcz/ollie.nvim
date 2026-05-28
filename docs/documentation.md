# ollie — Architecture Document

**Status:** Living document. Updated as subsystems evolve.  
**Audience:** Contributors, maintainers, and developers integrating or extending the plugin.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Philosophy](#2-architecture-philosophy)
3. [Module Responsibilities](#3-module-responsibilities)
4. [Request Lifecycle](#4-request-lifecycle)
5. [Streaming Lifecycle](#5-streaming-lifecycle)
6. [Async Execution Model](#6-async-execution-model)
7. [UI Rendering Flow](#7-ui-rendering-flow)
8. [Context Management](#8-context-management)
9. [Health Monitoring System](#9-health-monitoring-system)
10. [Selector and Provider Resolution](#10-selector-and-provider-resolution)
11. [Error Handling Strategy](#11-error-handling-strategy)
12. [Extension Points](#12-extension-points)
13. [Future Scalability Considerations](#13-future-scalability-considerations)

---

## 1. System Overview

`ollie.nvim` is a layered, asynchronous AI assistant for Neovim. It connects editor state to language model providers through a pipeline that is deliberately decomposed into isolated subsystems: context assembly, provider communication, response streaming, and UI rendering each live in separate modules with no direct coupling between non-adjacent layers.

The plugin is designed to support multiple simultaneous providers, hardware-aware model selection, and incremental response rendering — all without blocking the Neovim main thread.

### High-Level Component Map

```
+---------------------------------------------------------------+
|                        Neovim Editor                          |
|  Buffers   LSP Diagnostics   User Commands   Autocommands     |
+-----------------------------+---------------------------------+
                              |
                    +---------v----------+
                    |   commands/        |
                    |   (entry points)   |
                    +---------+----------+
                              |
               +--------------v--------------+
               |        core/router.lua       |
               |  (dispatch + coordination)   |
               +---+----------+----------+----+
                   |          |          |
         +---------v--+  +----v------+  +v-----------+
         |  handler/  |  | context/  |  |  selector  |
         |  (tasks)   |  | (assembly)|  |  (picker)  |
         +-----+------+  +----+------+  +------+-----+
               |              |                |
         +-----v--------------v----------------v-----+
         |              providers/                    |
         |  anthropic  openai  google  ollama         |
         +---------------------+----------------------+
                               |
                    +----------v----------+
                    |  streaming pipeline |
                    +----------+----------+
                               |
                    +----------v----------+
                    |     ui/ (render)    |
                    +---------------------+

         system/health/    system/security/
         (diagnostics)     (trust + policy)
```

Every arrow represents a one-way dependency. Lower layers have no knowledge of higher layers. The router is the only component that orchestrates across multiple subsystems.

commands -> router -> provider -> stream -> UI

---

## 2. Architecture Philosophy

### Layered, Not Monolithic

The codebase enforces a strict layer boundary model. Each subsystem is responsible for exactly one concern. This makes individual layers testable in isolation and replaceable without cascading changes.

### Dependency Direction Is One-Way

Higher layers depend on lower layers. Lower layers never import from higher layers. A provider module never touches `vim.api`. A UI module never constructs prompts. Violating this direction is the most common source of architectural debt in Neovim plugins and is explicitly avoided here.

### No Blocking the Main Thread

Neovim's main thread runs Lua synchronously. Any I/O — HTTP requests, CLI subprocess calls, file reads — that executes on the main thread freezes the editor. Every provider call, every subprocess, every file operation in this plugin is dispatched asynchronously via `vim.loop` or `vim.system`. Results are scheduled back onto the main thread via callbacks or coroutines only when needed to update UI state.

### Hardware-Aware by Default

The health and selector systems are first-class components, not optional diagnostics. The plugin probes the local environment at startup and surfaces model recommendations based on detected hardware. A user running on a low-memory machine should never be silently handed a model that will fail or perform poorly. The architecture supports this by keeping hardware context available to the selector layer at all times.

### Extensibility Over Configuration

New providers, handlers, and pickers are added by implementing a defined interface, not by modifying existing code. The router resolves providers and handlers by identifier, so new entries integrate without touching dispatch logic.

---

## 3. Module Responsibilities

### `plugin/ollie.lua`

The Neovim plugin entry point. Registers the plugin with Neovim's runtime, calls `require("ollie").setup()`, and defines all user-facing commands via `vim.api.nvim_create_user_command`. Contains no business logic. This file is intentionally minimal.

---

### `lua/ollie/init.lua`

The public API surface of the plugin. Exposes `setup()`, `set_provider()`, `set_model()`, and any other runtime-configurable functions. Holds the resolved configuration table after `setup()` is called. All other modules read configuration by requiring this module — there is no global state outside of it.

---

### `lua/ollie/commands/`

Thin command implementations. Each file in this directory corresponds to a user-facing command. Command files validate user input, resolve any command-level overrides (provider, model), and delegate to the router. They do not assemble context, call providers, or render output.

| File             | Responsibility                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------ |
| `chat.lua`       | Initialises and manages a chat session, maintains message history for the session lifetime |
| `keysuggest.lua` | Resolves current buffer context and delegates to the keymap suggestion handler             |

---

### `lua/ollie/core/router.lua`

The central coordinator. The router receives a request descriptor (handler type, provider override, model override, context payload) and orchestrates the following sequence: provider resolution, handler invocation, streaming setup, and result delivery to the UI layer.

The router does not implement any task logic. It is a dispatcher. It knows about providers and handlers only by their registered identifiers.

```lua
router.dispatch({
  handler  = "explain",
  provider = "anthropic",   -- optional override
  model    = "claude-3-5",  -- optional override
  context  = { ... },
})
```

---

### `lua/ollie/core/selector.lua`

Abstracts model and provider selection from the UI picker. The selector queries the health layer for available models on the current hardware, ranks them, and presents them via `vim.ui.select` or a registered picker (telescope, fzf-lua). The calling code receives a `{ provider, model }` pair and does not need to know which picker rendered the list.

---

### `lua/ollie/handler/`

Task handlers implement the semantic meaning of each command. A handler receives an assembled context object, constructs a prompt, calls the provider interface, and returns a stream handle or a resolved string to the router.

Each handler is a single-responsibility module:

| File           | Responsibility                                            |
| -------------- | --------------------------------------------------------- |
| `explain.lua`  | Builds explanation prompts from code context              |
| `fix.lua`      | Constructs fix prompts from code and LSP diagnostics      |
| `refactor.lua` | Builds refactor prompts with optional user-specified goal |
| `debug.lua`    | Analyses buffer state and diagnostic output for bugs      |
| `completion/`  | Handles cursor-position completion requests               |

Handlers have no knowledge of which provider will serve the request. They produce a prompt and a streaming callback interface. The router handles provider binding.

---

### `lua/ollie/handler/context/buff.lua`

Assembles the context payload passed to handlers. Responsibilities include:

- Extracting the current buffer content (full or visual selection)
- Collecting active LSP diagnostics for the buffer
- Resolving file type, file path, and relevant tree-sitter scope
- Enforcing the `max_lines` configuration limit
- Attaching any workspace-level metadata

Context assembly is synchronous and fast. It runs before the async dispatch begins.

---

### `lua/ollie/providers/`

Each provider module is a stateless adapter between the plugin's internal request format and a specific API or CLI. Providers must implement the following interface:

```lua
-- Every provider exposes these two functions:

provider.complete(request, on_chunk, on_done, on_error)
-- request:       { model, messages, options }
-- on_chunk(text) called for each streamed token
-- on_done()      called when the stream ends cleanly
-- on_error(err)  called on failure

provider.models()
-- returns a list of available model identifiers for this backend
```

Providers never call `vim.api`. They receive data and return data via callbacks. The transport layer (HTTP, subprocess, socket) is internal to each provider module.

| Provider     | Backends                                                            |
| ------------ | ------------------------------------------------------------------- |
| `anthropic/` | `cloud.lua` (Messages API), `claudecli.lua` (CLI subprocess)        |
| `openai/`    | `cloud.lua` (Chat Completions API), `codexcli.lua` (CLI subprocess) |
| `google/`    | `cloud.lua` (Gemini API), `localai.lua` (local inference server)    |
| `ollama/`    | `model.lua` (Ollama HTTP API, local)                                |

The `providers/init.lua` file acts as a registry. It maps provider identifiers to their module paths and exposes `providers.get(id)` for the router to use.

---

### `lua/ollie/ui/`

Responsible for all visible output. The UI layer receives text (incremental chunks or complete strings) and writes it to the appropriate Neovim buffer or window. It has no knowledge of providers, handlers, or context.

| File        | Responsibility                                                       |
| ----------- | -------------------------------------------------------------------- |
| `panel.lua` | Manages the persistent side/bottom panel buffer and window lifecycle |
| `front.lua` | Handles floating window creation and inline output rendering         |

The UI layer exposes a simple write interface:

```lua
ui.open(opts)      -- open the panel or float
ui.append(text)    -- append a chunk to the active output buffer
ui.finalise()      -- mark the stream as complete, unlock the buffer
ui.clear()         -- reset the output buffer
```

---

### `lua/ollie/system/health/`

Implements Neovim's `vim.health` interface. Runs a set of diagnostic checks and reports results via `:checkhealth ollie`.

| File           | Checks performed                                      |
| -------------- | ----------------------------------------------------- |
| `hardware.lua` | RAM available, CPU thread count, GPU presence         |
| `internet.lua` | Connectivity to provider API endpoints                |
| `models.lua`   | Model availability for each configured provider       |
| `ollama.lua`   | Ollama daemon reachability and loaded model list      |
| `init.lua`     | Aggregates all checks and registers with `vim.health` |

Health check results are also available programmatically via `health.get_capabilities()`, which the selector layer uses when ranking models.

---

### `lua/ollie/system/security/`

Manages trust boundaries and operation permissions.

| File             | Responsibility                                                         |
| ---------------- | ---------------------------------------------------------------------- |
| `permission.lua` | Checks whether a requested operation is permitted under current policy |
| `policies.lua`   | Defines the default and configurable policy ruleset                    |
| `trust.lua`      | Workspace trust state; marks a project as trusted or untrusted         |
| `init.lua`       | Public interface; exposes `security.check(operation)`                  |

Security checks are synchronous and run before any provider call is dispatched.

---

## 4. Request Lifecycle

The following describes the complete path of a user command from invocation to rendered output.

```
User triggers :OllieExplain
        |
        v
commands/explain.lua
  - validates input
  - reads command-level provider/model overrides
  - calls router.dispatch({ handler="explain", ... })
        |
        v
core/router.lua
  - calls security.check("explain")
  - calls context/buff.lua to assemble context payload
  - resolves provider via providers/init.lua
  - resolves handler via handler/explain.lua
  - calls handler(context) -> prompt
  - calls provider.complete(prompt, on_chunk, on_done, on_error)
        |
        v
providers/anthropic/cloud.lua  (example)
  - constructs API request payload
  - opens async HTTP connection via vim.loop
  - fires on_chunk(text) for each received token
  - fires on_done() or on_error(err) at completion
        |
        v
Streaming pipeline
  - on_chunk calls ui.append(text)
  - on_done  calls ui.finalise()
  - on_error calls ui.show_error(err)
        |
        v
ui/panel.lua or ui/front.lua
  - appends text to output buffer
  - schedules vim.api calls on the main thread via vim.schedule
```

The total number of synchronous operations on the main thread is minimal: context assembly (fast, local), security check (fast, local), and UI buffer writes (scheduled, batched).

---

## 5. Streaming Lifecycle

Streaming is the default response mode for all providers that support it. The lifecycle has four states:

```
IDLE -> OPEN -> STREAMING -> DONE
                    |
                    v
                  ERROR
```

**IDLE:** No active stream. The UI buffer is unlocked and editable.

**OPEN:** The provider has been called. The connection is being established. The UI buffer is locked for writing. A loading indicator may be displayed.

**STREAMING:** Tokens are arriving via `on_chunk` callbacks. Each chunk is passed directly to `ui.append()`, which schedules a `vim.api.nvim_buf_set_lines` call via `vim.schedule`. Chunks are not buffered unless the UI layer applies its own debounce.

**DONE:** `on_done()` fires. The router calls `ui.finalise()`, which unlocks the buffer and removes any loading indicator.

**ERROR:** `on_error(err)` fires at any point. The router calls `ui.show_error(err)`, which renders the error message and returns the buffer to IDLE state. The stream is cleanly terminated.

### Chunk Scheduling

Provider callbacks fire on `vim.loop` threads. Direct `vim.api` calls from these threads are not safe. All UI writes are wrapped in `vim.schedule(function() ... end)` to defer execution to the next safe main-thread iteration. This is the only point where async and sync contexts meet.

---

## 6. Async Execution Model

All I/O in the plugin is non-blocking. Two mechanisms are used depending on the provider backend.

### `vim.system` (Neovim >= 0.10)

Used for CLI-based providers (`claudecli`, `codexcli`) and subprocesses. `vim.system` runs a command in a background job and fires a callback on completion. Stdout is streamed line-by-line to simulate token streaming from CLI tools.

```lua
vim.system(
  { "claude", "--stream", "--prompt", prompt },
  {
    stdout = function(err, data)
      if data then on_chunk(data) end
    end
  },
  function(result)
    if result.code == 0 then on_done()
    else on_error(result.stderr) end
  end
)
```

### `vim.loop` (libuv HTTP)

Used for cloud API providers. HTTP connections are opened via `vim.loop.new_tcp()` with TLS handled by a bundled or system-provided library. Response bodies are read incrementally as they arrive and parsed for SSE (Server-Sent Events) tokens in the case of streaming APIs.

### Coroutine Wrapping

For sequences that require multiple async steps (e.g., fetch model list, then dispatch request), coroutines are used via `coroutine.wrap` to flatten the callback chain into readable sequential code without blocking the main thread.

### Thread Safety Rule

The boundary between async and sync is strictly enforced: async callbacks never call `vim.api` directly. They produce data, then schedule a function with `vim.schedule` to consume it on the main thread. This rule applies without exception throughout the codebase.

---

## 7. UI Rendering Flow

The UI layer is intentionally passive. It never initiates requests and never reads provider state.

### Panel Mode

`ui/panel.lua` manages a persistent buffer that survives across commands. When the panel is first opened, a dedicated split window and scratch buffer are created. Subsequent commands append to this buffer rather than replacing it, preserving conversation history within the session.

```
router calls ui.open({ mode = "panel" })
        |
        v
panel.lua checks if panel buffer exists
  - if not: nvim_create_buf + nvim_open_win
  - if yes: focus existing window
        |
        v
router calls ui.append(chunk) per token
        |
        v
panel.lua calls vim.schedule(function()
  nvim_buf_set_lines(buf, -1, -1, false, { chunk })
end)
        |
        v
router calls ui.finalise()
        |
        v
panel.lua scrolls to end, unlocks buffer
```

### Float Mode

`ui/front.lua` creates a temporary floating window for commands that produce inline output (explain, debug). The float is closed automatically after a configured timeout or on cursor movement.

### Thread Safety

All `nvim_*` API calls are wrapped in `vim.schedule`. This is enforced as a convention throughout the UI layer. No direct API calls are made from within provider callbacks.

---

## 8. Context Management

Context is assembled synchronously before each request is dispatched. The `handler/context/buff.lua` module is the single source of truth for what gets sent to the model.

### Context Payload Structure

```lua
{
  filetype    = "lua",
  filepath    = "/home/user/project/init.lua",
  content     = "...",       -- selected text or full buffer up to max_lines
  diagnostics = {            -- from vim.diagnostic.get()
    { lnum = 12, message = "undefined global 'foo'", severity = 1 },
  },
  cursor_pos  = { line = 14, col = 5 },
  scope       = "function",  -- treesitter scope if available
}
```

### Context Limits

The `max_lines` configuration value caps the number of lines included from the buffer. When the buffer exceeds this limit, the context assembly prioritises the region around the cursor or the active visual selection. Lines are trimmed symmetrically above and below the focal point.

### Diagnostics Inclusion

LSP diagnostics are included by default (`include_diagnostics = true`). Diagnostics are filtered to the current buffer and serialised into a compact format before being appended to the context payload. Handlers decide how to use diagnostic data — the fix handler includes them prominently; the explain handler may suppress them.

---

## 9. Health Monitoring System

The health system serves two purposes: user-facing diagnostics via `:checkhealth ollie`, and internal capability data used by the selector to rank model recommendations.

### Check Modules

**`hardware.lua`**
Reads system memory via `/proc/meminfo` (Linux) or `sysctl` (macOS). Counts available CPU threads. Detects CUDA or Metal GPU presence where possible. Produces a `capabilities` table consumed by the selector.

**`internet.lua`**
Attempts a lightweight TCP connection to each configured provider's API endpoint. Reports reachability status per provider. Does not make authenticated API calls.

**`models.lua`**
For each configured provider with a valid API key, fetches the model list and verifies that the configured default model is available. Reports mismatches.

**`ollama.lua`**
Checks whether the Ollama daemon is running on the configured host and port. Lists loaded models and their memory requirements. Warns if a loaded model exceeds available system RAM.

### Capability Data Flow

```
health/hardware.lua
        |
        v
health.get_capabilities()
  -> { ram_gb = 16, gpu = true, gpu_vram_gb = 8, ... }
        |
        v
core/selector.lua
  -> filters model list to those within hardware limits
  -> ranks remaining models by suitability
  -> presents ranked list to user
```

### `checkhealth` Output Format

Each check module calls `vim.health.ok()`, `vim.health.warn()`, or `vim.health.error()` with a message and optional advice string. The format follows Neovim's standard health report conventions so the output integrates naturally with other plugin health checks.

---

## 10. Selector and Provider Resolution

### Provider Resolution Order

When a command is invoked, the router resolves the active provider using the following priority:

```
1. Command-level override    (:OllieExplain provider=ollama)
2. Runtime override          (require("ollie").set_provider("ollama"))
3. Config default            (provider = "anthropic" in setup())
```

Model resolution follows the same order with an additional step: if no model is specified at any level, the selector's hardware-ranked default is used.

### Selector Flow

```
User triggers :OllieSelectModel
        |
        v
core/selector.lua
  - calls health.get_capabilities()
  - calls provider.models() for each available provider
  - filters models against hardware limits
  - ranks models (local first if GPU present, cloud fallback otherwise)
  - calls vim.ui.select() with ranked list
        |
        v
User selects { provider = "ollama", model = "llama3:8b" }
        |
        v
router stores selection as runtime override
```

### Picker Abstraction

The selector does not call telescope or fzf-lua directly. It calls `vim.ui.select()`, which plugins such as telescope and fzf-lua override at the `vim.ui` level. Picker integration therefore requires no code in the selector — users configure their preferred picker independently and the selector inherits it automatically.

---

## 11. Error Handling Strategy

Errors are categorised by origin and handled at the appropriate layer.

### Provider Errors

Network failures, authentication errors, rate limits, and malformed responses are caught within the provider module. The provider fires `on_error(err)` with a structured error table:

```lua
{
  type     = "auth_error",
  -- possible values: "auth_error" | "network_error" | "rate_limit" | "parse_error"
  message  = "401 Unauthorized: invalid API key",
  provider = "anthropic",
}
```

The router receives this and calls `ui.show_error(err)`. The error is rendered in the output panel with provider and error type context. The stream state is reset to IDLE.

### Handler Errors

If context assembly fails (empty buffer, no selection when required), the handler returns an error before any provider call is made. These errors are surfaced to the user immediately via `vim.notify`.

### Security Errors

If a security check fails, the router aborts before dispatching the request. A security denial is reported via `vim.notify` with a message indicating which policy was triggered.

### Health Check Errors

Health errors are non-fatal to the plugin's runtime. They are informational and displayed only via `:checkhealth ollie`. A failed health check does not prevent the user from attempting a request, but the selector will warn if a chosen model exceeds detected hardware limits.

### Error Propagation Rule

Errors do not bubble silently. Every error path must either call `on_error`, call `vim.notify`, or call `ui.show_error`. Swallowing errors without user feedback is not permitted.

---

## 12. Extension Points

The architecture provides well-defined integration points for contributors adding new functionality.

### Adding a New Provider

1. Create a directory under `lua/ollie/providers/<name>/`.
2. Implement the required interface:

```lua
-- lua/ollie/providers/myprovider/cloud.lua

local M = {}

function M.complete(request, on_chunk, on_done, on_error)
  -- request: { model, messages, options }
  -- perform async I/O, fire callbacks accordingly
end

function M.models()
  return { "myprovider-model-1", "myprovider-model-2" }
end

return M
```

3. Register the provider in `providers/init.lua`:

```lua
providers.register("myprovider", require("ollie.providers.myprovider.cloud"))
```

4. Add a corresponding health check in `system/health/` if the provider has local dependencies.

No changes to the router, selector, or handlers are required.

---

### Adding a New Handler

1. Create a file under `lua/ollie/handler/<name>.lua`.
2. Implement the handler interface:

```lua
-- lua/ollie/handler/summarise.lua

local M = {}

function M.build_prompt(context)
  return "Summarise the following code:\n\n" .. context.content
end

return M
```

3. Register the handler in `core/router.lua`'s handler table.
4. Add a command entry in `commands/` and register it in `plugin/ollie.lua`.

No changes to providers or UI are required.

---

### Adding a New Health Check

1. Create a file under `lua/ollie/system/health/<name>.lua`.
2. Implement a `check()` function using the `vim.health` API.
3. Register the check in `system/health/init.lua`.

---

### Replacing the UI Layer

The UI layer is accessed only through the interface functions exposed by `ui/front.lua` and `ui/panel.lua`. A contributor can replace the entire rendering implementation by providing a module that satisfies the same interface (`open`, `append`, `finalise`, `clear`, `show_error`) without touching any other part of the codebase.

---

## 13. Future Scalability Considerations

### Multi-Request Concurrency

The current model dispatches one request at a time per command invocation. Future work should consider a request queue manager that allows multiple concurrent streams (e.g., background refactor alongside foreground chat) with per-request cancellation support via `vim.loop` handle management.

### Workspace-Level Context

The current context system operates at the buffer level. A workspace context layer would assemble project-wide context from git diff, LSP workspace symbols, and open buffers. This would slot in as an additional context source in `handler/context/` without changing handler or provider interfaces.

### Provider Tool Use

Several providers support structured tool calling (function calling). Supporting this requires an additional message type in the provider interface and a tool registry in the router. The current interface can accommodate this by extending the `request` object without breaking existing providers.

### Session Persistence

Chat session history is currently in-memory and lost on Neovim exit. A persistence layer would serialise session state to a local file or SQLite database. This would be implemented in `commands/chat.lua` without touching the router, provider, or UI interfaces.

### Plugin Splitting

As the codebase grows, individual subsystems (health, security, context) could be extracted into standalone Neovim plugins with defined API contracts. The current architecture supports this because subsystems already communicate through narrow interfaces rather than shared state.

### Telemetry and Metrics

A future metrics module could instrument the router to record request latency, error rates, and model usage — entirely opt-in and local. The router's central position makes it the natural instrumentation point without requiring changes elsewhere.

---

_This document reflects the architecture as currently implemented. Sections marked with future work describe intended directions, not committed features._
