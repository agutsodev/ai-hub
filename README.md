# AI hub

A shell script to interact with LLM [providers](./provider/) on your terminal.

## Installation

- Clone this repo
- Set execution permission
- Map an alias on your shell configuration

```bash
git clone https://github.com/agutsodev/ai-hub.git ~/.ai-hub && chmod +x ~/.ai-hub/main.sh && echo "alias ai='~/.ai-hub/main.sh'" >> ~/.zshrc && source ~/.zshrc
```

## Usage

### Prompt once

**ai "prompt"**

This options answers to a single prompt.

```bash
ai "what are the top 3 most popular programing languages?"
```

### Start a chat session

**ai [--chat|-c] assistant-role**

This options handle multiple sequential prompts.

- Using the default assistant role

  ```bash
  ai --chat
  ```

- Supply a custom assistant role

  ```bash
  ai --chat "You are a tech expert"
  ```

After that the actual chat will start.

> The assistant role is used to tell the chat which role should be acted.

### Generate shell commands

**ai [--shell|-s] prompt**

This options answers a single prompt that aims to generate a shell command.

```bash
ai --shell
```

```bash
ai --shell "list the name, path and size of the 5 biggest files on my computer"
```

> This is achieved by adding a prefix (`AIHUB_SHELL_PREFIX`) to your actual prompt.

### Generate code

**ai [--code|-C] language**

This options answers a single prompt that aims to generate code for a given language.

```bash
ai --code
```

```bash
ai --code java
```

After that the actual prompt should be provided.

> This is achieved by adding a prefix (`AIHUB_CODE_PREFIX`) to your actual prompt.

### Switch LLM model provider

**ai [--provider|-p]**

```bash
ai --provider
```

```bash
ai -p
```

> Provider state will be saved to `.env.state`.

### Usage helper

**ai [--help|-h]**

```bash
ai -h
```

```bash
ai --help
```

## Configuration

Available environment variables. Create a `.env` to override the default config.

| Var                      | Description                                    |
| ------------------------ | ---------------------------------------------- |
| AIHUB_TEMPERATURE        | Temperature for API calls.          |
| AIHUB_MAX_TOKENS         | Max tokens for completion API calls.           |
| AIHUB_ROLE               | Default assistant role to start chat sessions. |
| AIHUB_SHELL_PREFIX       | Prefix to shell generation prompts.            |
| AIHUB_CODE_PREFIX        | Prefix to code generation prompts.             |


> API keys will be prompted and saved to `.env.keys`.

> All iterations are stored at 📁`log` folder as a `.txt` file.