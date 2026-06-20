# Architecture Overview

This document describes the internal architecture of Ollie.nvim, including request flow, module responsibilities, and system boundaries.

Ollie is designed as a modular LLM orchestration layer for Neovim, separating UI, execution, routing, and provider logic into independent components.

</br>

## System Design Principles

The architecture follows these constraints:

- UI is isolated from execution logic
- Providers are interchangeable modules
- Routing is centralized and deterministic
- Chat execution is stateless per request
- Session state is persistent but non-blocking
- Streaming is handled asynchronously via callbacks

---

## High-Level Architecture

```text
User Input
    |
UI Layer (ui.behaviour.input)
    |
Command Layer (commands/chat.lua)
    |
Handler Layer (handler/chat)
    |
Core Orchestration (runtime + router)
    |
Provider Layer (ollie.providers.*)
    |
External API (Ollama / OpenAI / etc.)
    |
Streaming Response
    |
UI Renderer (window + render)
```

---

## Module Responsibilities

### 1. UI Layer (`lua/ollie/ui/`)

Responsible for all Neovim interaction.

### Components

- `input.lua` → captures user input
- `window.lua` → buffer/window management
- `render.lua` → formatting output
- `notify.lua` → status updates
- `task_router.lua` → input event routing (chat/debug/explain)

### Responsibilities

- collect user input
- render chat output
- display streaming chunks
- manage buffer lifecycle

### Boundaries

- must not call providers directly
- must not build prompts
- must not handle session logic

</br>

## 2. Command Layer (`lua/ollie/commands/`)

Entry point for user-facing commands.

### Examples

- `chat.lua`
- `debug.lua`
- `models.lua`

### Responsibility

- define `:OllieChat`, `:OllieFix`
- convert CLI input into handler calls
- initialize UI session

### Constraints

- no business logic
- no provider access
- no prompt construction

</br>

## 3. Handler Layer (`lua/ollie/handler/`)

Responsible for request transformation and validation.

### Example

- `handler/chat/init.lua`
- `prompt.lua`
- `validate.lua`

### Responsibility

- validates input
- construct prompt payload
- decide context inclusion
- transform query → structured request

### Output

Structured request object passed to core runtime.

---

## 4. Core Layer (`lua/ollie/core/`)

This is the execution backbone.

### Component

- `router.lua`
- `runtime.lua`
- `session.lua`
- `message.lua`
- `response.lua`
- `stream.lua`
- `cache.lua`
- `selector.lua`

### 4.1 Router

Responsible for request dispatch:

- selects provider
- executes request
- manages streaming lifecycle

It does NOT interpret prompts.

---

### 4.2 Runtime

Responsible for:

- resolving provider (`runtime.provider()`)
- resolving model (`runtime.model()`)
- determining streaming mode

---

### 4.3 Session

Stores conversation state:

- user messages
- assistant messages
- history per buffer/session

---

### 4.4 Stream

Handles incremental response processing:

- chunk normalization
- buffering
- forward streaming events

</br>

## 5. Provider Layer (`lua/ollie/providers/`)

Encapsulates external LLM APIs.

### Structure

```text
providers/
├── ollama/
├── openai/
├── anthropic/
```

Each provider must implement:

- `chat()`
- `stream()`
- `validate()`
- optional `models()`

### Responsibilities

- API communication
- authentication
- request execution
- streaming responses

### Constraints

- no UI access
- no session access
- no prompt building logic

</br>

## 6. Parser Layer (`lua/ollie/parser/`)

Responsible for response processing.

### Components

- `chunks.lua` → streaming chunk normalization
- `sanitise.lua` → output cleanup
- `init.lua` → parser entry

### Responsibilities

- convert raw API output → usable text
- ensure safe rendering
- handle partial streams

</br>

## 7. System Layer (`lua/ollie/system/`)

Handles cross-cutting concerns.

### 7.1 Security

- permissions
- trust policies
- execution constraints

### 7.2 Health

- provider health checks
- model availability
- system diagnostics

</br>

## 8. Context Layer (`lua/ollie/core/context/`)

Provides contextual augmentation.

### Components

- `buff.lua` → buffer-based context extraction
- `selection.lua` → visual selection context

### Responsibilities

- extract editor context
- inject context into prompts
- ensure context consistency

# Request Lifecycle

## Step 1: User Input

User triggers:

```
:OllieChat
```

or presses `<CR>` in UI.

---

## Step 2: Command Layer

Command receives input and calls:

```
handler/chat
```

---

## Step 3: Handler Processing

Handler performs:

- validation
- context resolution
- prompt building

Output:

```
structured request
```

---

## Step 4: Core Routing

Router:

- selects provider
- selects model
- executes request

---

## Step 5: Provider Execution

Provider:

- sends HTTP request
- streams response
- emits chunks

---

## Step 6: Streaming Pipeline

Chunks flow:

```
provider → router → stream → UI renderer
```

---

## Step 7: UI Rendering

UI:

- formats chunks
- updates buffer
- displays completion state

---

## Step 8: Session Storage

Final response stored in:

```
session.lua
```

---

# State Management Model

Ollie uses three state layers:

## 1. Ephemeral State (UI)

- input buffer
- temporary UI state
- streaming state

## 2. Session State (core/session.lua)

- chat history
- role-based message log

## 3. Global Runtime State (core/runtime.lua)

- active provider
- active model
- streaming configuration

---

# Concurrency Model

Ollie is event-driven:

- no blocking UI calls
- all streaming uses `vim.schedule`
- router uses callback-based execution

Concurrency safety relies on:

- `input.finish()` locks
- router request isolation
- per-request local state

---

# Design Boundaries

## UI must NOT:

- call providers
- build prompts
- mutate session directly

## Handler must NOT:

- render UI
- execute HTTP requests

## Provider must NOT:

- access Neovim API
- access session
- manage context

## Core must NOT:

- depend on UI rendering logic

---

# Extension Points

## Adding a Provider

- implement provider interface
- register in `providers/init.lua`

## Adding a Command

- create file in `commands/`
- call handler layer only

## Adding a Handler

- define `init.lua`
- define `validate.lua`
- define `prompt.lua`

---

# Failure Model

Ollie handles failures at three levels:

## 1. Validation failure

Handled in handler layer

## 2. Execution failure

Handled in router/provider layer

## 3. UI failure

Handled via notify system

# Summary

Ollie architecture is designed as a layered, event-driven LLM orchestration system with strict separation between:

- UI (Neovim interaction)
- Command interface
- Handler transformation
- Core routing
- Provider execution
- Streaming and rendering

This separation ensures:

- extensibility
- provider independence
- UI stability
- predictable request flow
