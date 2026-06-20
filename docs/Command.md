# Ollie.nvim Command Lines

This file lists the commands currently registered by `ollie.nvim`.

## Main Window

```vim
:Ollie
```

Opens the main Ollie chat window and asks for input. This command starts a chat session and does not include buffer context by default.

</br>

```vim
:OllieHelp
```

Opens a read-only help window. It loads:

</br>

```text
1. documentation
2. command lines
3. configuration
```

</br>

## Chat

```vim
:OllieChat
```

Starts a chat session without sending the current buffer content by opening window. Hit return/enter when you want to send query.

</br>

```vim
:OllieChat <user query>
```

Starts chat immediately with the given text.

</br>

```vim
:OllieChatContext
```

Starts a chat session with the current buffer content, cursor position, and filetype.

</br>

```vim
:OllieChatContext <user query>
```

</br>

## Selected Code

Sends the current buffer context and the question to the selected model.
Run these commands over a visual range or with a range.

</br>

```vim
:'<,'>OllieExplain
```

Explains the selected code in the explain panel.

</br>

```vim
:'<,'>OllieExplain <user query>
```

Explains selected code with a specific question.

</br>

```vim
:'<,'>OllieFix
```

</br>

Asks Ollie to fix the selected code.

```vim
:'<,'>OllieFix <user query>
```

Asks Ollie to fix selected code with a specific goal.

</br>

## Sessions

```vim
:OllieSessions
```

Opens the session picker. And loads the conversation history.

Inside the picker:

```text
Enter -> switch to selected session and open it in a fresh chat window
x     -> close the active chat window
r     -> refresh the session list
q     -> close the picker
Esc   -> close the picker
```

</br>

```vim
:OllieSessionDelete
```

Deletes the active session.

</br>

```vim
:OllieSessionDelete <session_id>
```

Deletes a specific session.

</br>

```vim
:OllieSessionClear
```

Deletes all cached sessions.

</br>

## Models and Providers

```vim
:OllieModel <model_name>
```

Switches the active model. Example:

```vim
:OllieModel qwen2.5-coder:3b
```

</br>

```vim
:OllieListModels
```

Lists models exposed by the current provider.

</br>

```vim
:OllieProvider <provider_name>
```

Switches the active provider. The current provider implementation is `ollama`.

</br>

```vim
:OllieListProviders
```

</br>

Lists registered providers.

## Health

```vim
:OllieHealth
```

</br>

Shows local hardware, Ollama status, and recommended provider/model information.
