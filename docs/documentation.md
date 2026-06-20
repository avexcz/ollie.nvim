# Ollie.nvim Documentation

`ollie.nvim` is a Neovim assistant that connects editor commands to a local model provider. The current implementation focuses on Ollama, chat windows, context-aware prompts, selected-code explain/fix actions, model switching, session history, health checks, and security checks before a request is sent.

The plugin is split into small modules. Commands stay thin, handlers build prompts, the router chooses the provider and model, providers talk to the model backend, and UI modules render the result.
</br>

## Request Flow

Simple flow:

```text
User command -> handler -> router -> provider -> model response -> renderer -> Neovim window
```

Chat with context:

```text
:OllieChatContext -> capture current buffer -> build prompt -> router -> Ollama -> chat window
```

Selected-code tools:

```text
Visual range -> :OllieExplain or :OllieFix -> prompt builder -> panel window
```

</br>

## Folder Tree

```text
Am5hoo ollie.nvim > tree
.
├── docs
│   ├── command_lines.md
│   ├── configuration.md
│   └── documentation.md
├── lua
│   └── ollie
│       ├── init.lua
│       |
│       ├── commands
│       │   ├── chat.lua
│       │   ├── debug.lua
│       │   ├── health.lua
│       │   ├── help.lua
│       │   └── models.lua
│       |
│       ├── core
│       │   ├── cache.lua
│       │   ├── config.lua
│       │   ├── context
│       │   │   ├── buff.lua
│       │   │   └── selection.lua
│       │   ├── message.lua
│       │   ├── response.lua
│       │   ├── router.lua
│       │   ├── runtime.lua
│       │   ├── selector.lua
│       │   ├── session.lua
│       │   └── stream.lua
│       |
│       ├── handler
│       │   ├── chat
│       │   │   ├── init.lua
│       │   │   ├── prompt.lua
│       │   │   └── validate.lua
│       │   ├── debug
│       │   │   ├── init.lua
│       │   │   ├── prompt.lua
│       │   │   └── validate.lua
│       │   └── explain
│       │       ├── init.lua
│       │       ├── prompt.lua
│       │       └── validate.lua
│       |
│       ├── parser
│       │   ├── chunks.lua
│       │   ├── init.lua
│       │   └── sanitise.lua
│       |
│       ├── providers
│       │   ├── init.lua
│       │   └── ollama
│       │       ├── boostrap.lua
│       │       └── model.lua
│       |
│       ├── system
│       │   ├── health
│       │   │   ├── hardware.lua
│       │   │   ├── init.lua
│       │   │   ├── models.lua
│       │   │   └── ollama.lua
│       │   └── security
│       │       ├── init.lua
│       │       ├── permission.lua
│       │       ├── policies.lua
│       │       └── trust.lua
│       |
│       └── ui
│           ├── behaviour
│           │   ├── cursor_controller.lua
│           │   ├── format.lua
│           │   ├── input.lua
│           │   ├── resize.lua
│           │   └── task_router.lua
│           |
│           ├── notify.lua
│           ├── render.lua
│           ├── session_ui.lua
│           └── windows
│               ├── front.lua
│               ├── panel.lua
│               └── window.lua
├── plugin
│   └── ollie.lua
├── README.md
└── stylua.toml

21 directories, 57 files
```

</br>

## Main Modules

### `init.lua`

`init.lua` is the plugin entry point. It loads command modules, registers the top-level `:Ollie` command, runs setup for config, router, security, resize handling, health, model commands, chat commands, and help.

Example:

```lua
require("ollie").setup({})
```

This is the smallest valid setup. It keeps the default provider as `ollama`, default model as `avexcoder_3b:latest`, and streaming enabled.

## `commands/`

Command files register user commands and then delegate work to handlers or UI helpers.

Important commands:

```text
:Ollie
:OllieHelp
:OllieChat
:OllieChatContext
:OllieFix
:OllieExplain
:OllieSessions
:OllieModel
:OllieProvider
:OllieHealth
```

The command layer should not call model APIs directly. It should collect command arguments, start sessions when needed, and pass work to the right handler.

</br>

## `core/`

```text
core/
├── cache.lua
├── config.lua
├── context
│   ├── buff.lua
│   └── selection.lua
├── message.lua
├── response.lua
├── router.lua
├── runtime.lua
├── selector.lua
├── session.lua
└── stream.lua
```

### Router

The router is the final request dispatcher. It's responsibility is routing models, providers and given model's task. It sends request after permission is checked in order to generate response provided by the provider's model. It's hierarchy dependency tree would be:

```text
task -> provider -> model -> permission check -> provider.generate()
```

It also calls `on_error` for hidden failures, such as missing providers, blocked security policy, empty prompt, or provider startup errors.

### Selector

The selector stores the active provider and model. `:OllieModel qwen2.5-coder:3b` updates selector state, and router reads that state before sending the next request.

For example, `:OllieChat` does not include this buffer content. But `OllieChatContext` does.

### Context

It is divided into two types. One is the entire buffer description and selection description.

#### 1. buffer (buff.lua)

This module captures editor context for `:OllieChatContext`. It returns:

```lua
{
  buffer_content = "...",
  cursor_position = { line = 10, col = 4 },
  filetype = "lua",
}
```

#### 2. selection

It's job is to provide brief details about it's cursor position, line number, coloums and so on. This captures the selected portion for ollie to receive the user data, with it's file names, position and more details along with user prompt.

### Session

Sessions store chat messages and save them through `core/cache.lua` Cache is responsible for loading the chat log activities of user's past history. The session UI reads session rows and can open a previous chat in a fresh chat window.

### Stream

It's responsibility is to perform the operation lifecycle consisting of initialization, data ingestion, and termination in this current stage.

### Configuration

There is a `config.lua` file which have it's table of default model, provider and it's default engine components and formatter.

</br>

## `handler/`

Handlers define task behaviour. Currently it consist of three types- chat, debug and explain handlers. Their job is to mainly send request with user prompts after validating user query so that no any other uncommon character in user prompt exist.

```text
chat -> validates user query, builds chat prompt, opens chat window
debug -> builds fix prompt from selected code
explain -> builds explanation prompt from selected code
```

Handlers should build prompts and attach callbacks. They should not own provider selection directly.

### `providers/`

Provider modules convert Ollie requests into backend requests. The active provider is currently `ollama`.

Request body example:

```lua
{
  model = "qwen2.5-coder:3b",
  prompt = "Explain this function",
  stream = true,
}
```

The Ollama provider starts or checks Ollama, sends a `curl` request to `/api/generate` via asynchronous `vim.jobstart`, streams chunks, and calls completion/error callbacks.

For those who want to add a new provider, here is suggested way to develop a new provider engine.

```text
├── init.lua
├── new_provider (i.e- Anthropic)
    └── claude.lua
```

<b>Provider Interface Contract </b>

```lua
-- required interface
local Provider = {}

function Provider.chat(opts, on_chunk, on_complete, on_error)
end

function Provider.stream(opts, on_chunk, on_complete, on_error)
end

function Provider.models()
end

function Provider.validate()
end

return Provider

```

Firstly configuration should be loaded in new provider engine file. Validation to prove whether API key is added or not, and from there creating a chat request engine begins. You may list public model API function to satisfy a provider contract abstraction layer.

After that, update the `init.lua` initialization file.

```lua
M.providers = {
    ollama = require("ollie.providers.ollama.model")
    anthropic = require("ollie.providers.anthropic.claude")
}
```

### `ui/`

UI modules own visible output only.

```text
ui/windows/window.lua -> opens chat, fix, and explain windows
ui/session_ui.lua -> lists sessions and opens selected chats
ui/render.lua -> formats user, assistant, chunk, and error text
ui/behaviour/input.lua -> asks for user input and attaches keys
```

</br>

## Context Rules

`OllieChat`:

```text
User query -> model
```

No buffer content is added.

`OllieChatContext`:

```text
Current buffer -> context prompt -> user query -> model
```

The buffer is captured before the chat window opens, so the source file is used instead of the Ollie output buffer.

## Session Flow

```text
start session -> add user message -> model response -> add assistant message -> cache session
```

Open sessions with:

```vim
:OllieSessions
```

Inside the session window:

```text
Enter -> open selected session in a fresh chat window
x     -> close active chat window
r     -> refresh session list
q     -> close session picker
```

</br>

## Security and Health

Before dispatch, the router calls security permission checks. Current checks include trusted workspace, allowed provider, and prompt size limit.

Health checks inspect local hardware and Ollama status. Use:

```vim
:OllieHealth
```

This helps confirm whether Ollama is reachable and which model is recommended.
