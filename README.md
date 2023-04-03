# GPT script

A shell script to interact with GPT on your terminal.

## Installation

Clone this repo

```bash
git clone https://github.com/augusto-gtns/gpt.git
```

Generate and set your personal API key (https://platform.openai.com/account/api-keys)

```bash
export OPENAI_API_KEY=mykey
```

> If not found `OPENAI_API_KEY` will be prompted and saved to `.env.custom`.

Set execution permission

```bash
chmod +x gpt.sh
```

## Usage

Run the script on your terminal

- call the script

  ```bash
  ./gpt.sh
  ```

- or map an alias on your shell configuration (`.bashrc`, `.zshrc` or others) and call the given alias

  ```bash
  alias gpt="~/gpt.sh"
  ```

  ```bash
  gpt
  ```

### Prompt once

**gpt prompt**

This options uses the completion API to answer a single prompt.

```bash
gpt "what are the top 3 most popular programing languages?"
```

### Start a chat session

**gpt [--chat|-c] assistant-role**

This options uses the chat API to handle multiple sequential prompts.

- Using the default assistant role

  ```bash
  gpt --chat
  ```

- Supply a custom assistant role

  ```bash
  gpt --chat "You are a tech expert"
  ```

After that the actual chat will start.

> The assistant role is used to tell the chat which role should be acted.

### Generate shell commands

**gpt [--shell|-s] prompt**

This options uses the completion API to answer a single prompt that aims to generate a shell command.

This is achieved by adding a prefix (`OPENAI_SHELL_PREFIX`) to your actual prompt.

```bash
gpt --shell
```

```bash
gpt --shell "list the name, path and size of the 5 biggest files on my whole computer"
```

### Generate code

**gpt [--code|-C] language**

This options uses the completion API to answer a single prompt that aims to generate code for a given language.

This is achieved by adding a prefix (`OPENAI_CODE_PREFIX`) to your actual prompt.

```bash
gpt --code
```

```bash
gpt --code java
```

After that the actual prompt should be provided.

### See the usage helper:

**gpt [--help|-h]**

```bash
gpt -h
```

```bash
gpt --help
```

> All chat or prompt iterations are stored at 📁`log` folder as a `.txt` file.

## Configuration

Available environment variables. Create a `.env.custom` to override the default config.

| Var                      | Description                                    |
| ------------------------ | ---------------------------------------------- |
| OPENAI_API_KEY           | Your personal API key.                         |
| OPENAI_COMPL_MODEL       | Model used for completion API calls.           |
| OPENAI_COMPL_TEMPERATURE | Temperature for completion API calls.          |
| OPENAI_COMPL_MAX_TOKENS  | Max tokens for completion API calls.           |
| OPENAI_CHAT_MODEL        | Model used for chat API calls.                 |
| OPENAI_CHAT_ROLE         | Default assistant role to start chat sessions. |
| OPENAI_CHAT_TEMPERATURE  | Temperature for chat API calls.                |
| OPENAI_SHELL_PREFIX      | Prefix to shell generation prompts.            |
| OPENAI_CODE_PREFIX       | Prefix to code generation prompts.             |

> Temperature vars require values between 0 and 2. Higher values make the output more random, lower values make it more deterministic.

## Reference

- [OpenAI API docs](https://platform.openai.com/docs/api-reference)
