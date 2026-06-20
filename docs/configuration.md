# Ollie.nvim Configuration

Ollie works with an empty setup, but you can tune provider, model, streaming, router rules, and security policy.

</br>

## Minimal Setup

```lua
require("ollie").setup({})
```

</br>

Use this when you want the defaults:

```text
provider -> ollama
model    -> avexcoder_3b:latest
stream   -> true
```

</br>

## Recommended Local Setup

```lua
require("ollie").setup({
  default_provider = "ollama",
  default_model = "qwen2.5-coder:3b",
  streaming = true,
})
```

This is useful for local coding tasks. Streaming keeps the UI responsive and `qwen2.5-coder:3b` is a practical coding model when available in Ollama.

</br>

Switch model during a session:

```vim
:OllieModel qwen2.5-coder:3b
```

The router reads the selected model before sending new requests.

</br>

## Router Rules

Router rules provide default provider and model per task.

```lua
require("ollie").setup({
  router = {
    rules = {
      chat = {
        provider = "ollama",
        model = "qwen2.5-coder:3b",
      },
      fix = {
        provider = "ollama",
        model = "avexcoder_3b:latest",
      },
      explain = {
        provider = "ollama",
        model = "qwen2.5-coder:1.5b",
      },
    },
    defaults = {
      stream = true,
    },
  },
})
```

Use task rules when you want different models for chat, explain, and fix.

</br>

## Security Policy

Security settings are passed under `security`.

```lua
require("ollie").setup({
  security = {
    allow_network = true,
    allow_providers = {
      ollama = true,
    },
    max_prompt_chars = 120000,
  },
})
```

Recommended values:

```text
allow_network      -> true for Ollama requests
allow_providers    -> keep only providers you use
max_prompt_chars   -> lower this if large files are too slow
```

</br>

## Context Behavior

Use plain chat when you do not want buffer content sent:

```vim
:OllieChat
```

Use context chat when the model needs the current buffer:

```vim
:OllieChatContext
```

`OllieChatContext` captures:

```text
buffer_content
cursor_position
filetype
```

</br>

## Useful Setup Example (recommanded)

```lua
require("ollie").setup({
  default_provider = "ollama",
  default_model = "qwen2.5-coder:3b",
  streaming = true,

  router = {
    defaults = {
      stream = true,
    },
  },

  security = {
    allow_network = true,
    allow_providers = {
      ollama = true,
    },
    max_prompt_chars = 80000,
  },
})
```

This setup is a good default for local development: it keeps Ollama enabled, streams responses, and limits very large prompts.
