# Contributing to Ollie.nvim

This document defines development standards, architecture rules, and contribution workflow for Ollie.nvim.

Ollie is a modular Neovim plugin for LLM interaction. Contributions must respect the layered architecture and maintain separation of concerns.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Development Principles](#development-principles)
- [Code Architecture Rules](#code-architecture-rules)
- [Adding Features](#adding-features)
- [Adding Providers](#adding-a-new-provider)
- [Adding Commands](#adding-a-new-command)
- [Adding Handlers](#adding-a-handler)
- [UI Development Rules](#ui-development-rules)
- [Testing Guidelines](#testing-guidelines)
- [Error Handling Standards](#error-handling-standards)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)

---

## Project Structure

```
lua/ollie/
├── commands/     # User-facing entry points
├── core/         # Runtime, routing, session, state
├── handler/      # Validation + prompt building
├── providers/    # LLM integrations
├── parser/       # Response parsing and sanitization
├── system/       # Security + health
├── ui/           # Neovim interface layer
```

Each layer has strict responsibilities and must not leak concerns into other layers.

---

## Development Principles

All contributions must follow these rules:

1. Strict separation of concerns
2. UI must not execute business logic
3. Providers must not access Neovim APIs
4. Core must remain UI-agnostic
5. Handler must not perform network requests
6. All async operations must be callback-based
7. No global mutable state unless explicitly justified

---

## Code Architecture Rules

### Layer Boundaries

#### UI Layer (`ui/`)

Allowed:

- rendering
- buffers
- input handling

Not allowed:

- API calls
- session mutation
- prompt building

---

#### Command Layer (`commands/`)

Allowed:

- defining user commands
- forwarding requests to handlers

Not allowed:

- execution logic
- provider calls

---

#### Handler Layer (`handler/`)

Allowed:

- validation
- prompt construction
- request shaping

Not allowed:

- UI rendering
- HTTP requests

---

#### Core Layer (`core/`)

Allowed:

- routing
- runtime resolution
- session management

Not allowed:

- UI dependencies
- provider-specific logic

---

#### Provider Layer (`providers/`)

Allowed:

- external API calls
- streaming responses
- model listing

Not allowed:

- UI interaction
- session access
- prompt construction

---

## Adding Features

When adding a feature:

1. Identify correct layer
2. Avoid cross-layer logic mixing
3. Ensure feature does not bypass router
4. Maintain async safety

---

## Adding a New Provider

All providers must implement:

```
chat()
stream()
validate()
(optional) models()
```

#### Example structure:

```
lua/ollie/providers/<name>/
├── init.lua
├── model.lua (optional)
```

#### Requirements:

- Must return streamed chunks via callbacks
- Must not depend on UI or core session
- Must be registered in `providers/init.lua`

---

## Adding a New Command

Commands define user-facing entry points.

Example:

```
lua/ollie/commands/mycommand.lua
```

Rules:

- Must only call handler layer
- Must not contain business logic
- Must be registered in `plugin/ollie.lua`

---

## Adding a Handler

Handlers transform input into structured requests.

Structure:

```
handler/<feature>/
├── init.lua
├── validate.lua
├── prompt.lua
```

Rules:

- validation must be explicit
- prompt building must be deterministic
- no UI calls allowed

---

## UI Development Rules

UI layer must:

- remain stateless where possible
- use `vim.schedule` for async updates
- never block execution
- never mutate core state directly

UI components include:

- windows
- input system
- rendering system
- notifications

---

## Error Handling Standards

All errors must follow:

- Logged via `vim.notify`
- Include module name context
- Never silently fail

Example:

```
vim.notify("Provider failed: openai", vim.log.levels.ERROR)
```

---

## Code Style

- Follow `stylua.toml`
- Use local modules, avoid globals
- Prefer explicit returns
- Avoid deeply nested callbacks where possible
- Keep functions single-responsibility

---

## Pull Request Process

Before submitting a PR:

1. Ensure no runtime errors
2. Ensure no UI regressions
3. Verify provider integration (if changed)
4. Run manual chat test:
   - open chat
   - send 3 consecutive messages
   - verify no input lock

5. Validate no duplicate commands exist

---
