# fish-kimi-cli

Fish shell plugin for [Kimi CLI](https://github.com/MoonshotAI/kimi-cli) - a port of the zsh plugin with improvements.

## Usage

Press **Ctrl-X** to toggle prefix mode:

```fish
# Press Ctrl-X - you'll see "✨ " appear at the start of the line
✨ explain this error

# Press Enter - it runs: kimi -c "explain this error"

# Next prompt also starts with "✨ " (mode stays active)
# Press Ctrl-X again to exit prefix mode
```

## Improvements Over Zsh Version

1. **Better guards**: Also prevents left arrow and Home key from moving into prefix (zsh only guards delete and kill-word)
2. **Status function**: Check if prefix mode is active (useful for custom prompts)

## Installation

```fish
fisher install lemon07r/fish-kimi-cli
```

## Configuration

Change the prefix in `~/.config/fish/config.fish`:

```fish
set -g __kimi_cli_prefix "ask "
```

## Status Function

Check if prefix mode is active:

```fish
# Check status
__kimi_cli_status
# Output:
# kimi-cli: prefix mode is active
# kimi-cli: prefix: '✨ '

# Use in your prompt (quiet mode)
function fish_prompt
    if __kimi_cli_status -q
        echo "[KIMI] "
    end
    # ... rest of your prompt
end
```

## How it works

1. **Ctrl-X** toggles prefix mode on/off
2. When active, new prompts automatically start with the prefix
3. Guards prevent you from accidentally deleting or moving into the prefix
4. The command is sent to `kimi -c "your command"`

## Requirements

- Fish shell 3.0+
- Kimi CLI installed
