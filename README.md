# fish-kimi-cli

Fish shell plugin for [Kimi CLI](https://github.com/MoonshotAI/kimi-cli) - a port of the [zsh plugin](https://github.com/MoonshotAI/zsh-kimi-cli) with improvements.

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

1. **Better guards**: Also prevents left arrow, Home key, Alt-B (backward word), and Ctrl-U from affecting the prefix
2. **Ctrl-U protection**: Only clears content after the prefix (zsh version has no Ctrl-U guard)
3. **Status function**: Check if prefix mode is active (useful for custom prompts)
4. **Preserves existing handlers**: If you have a custom `fish_command_not_found`, it will be preserved

## Installation

### Fisher

```fish
fisher install lemon07r/fish-kimi-cli
```

### Manual

```fish
# Clone the repo
git clone https://github.com/lemon07r/fish-kimi-cli.git ~/.config/fish/plugins/fish-kimi-cli

# Add to config.fish
source ~/.config/fish/plugins/fish-kimi-cli/conf.d/kimi-cli.fish
```

## Configuration

Change the prefix character in `~/.config/fish/config.fish` (before the plugin loads):

```fish
# Must be set before the plugin loads
set -g __kimi_cli_prefix_char "🤖"
# Or set the full prefix (including trailing space)
set -g __kimi_cli_prefix "ask: "
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
        set_color magenta
        echo -n "[KIMI] "
        set_color normal
    end
    # ... rest of your prompt
end
```

## Key Bindings

| Key | Action |
|-----|--------|
| Ctrl-X | Toggle prefix mode on/off |
| Backspace | Delete (guarded - won't delete prefix) |
| Ctrl-W | Kill word backward (guarded) |
| Left / Ctrl-B | Move left (guarded - won't enter prefix) |
| Alt-B / Alt-Left | Move word backward (guarded) |
| Home / Ctrl-A | Go to start (guarded - stops at prefix end) |
| Ctrl-U | Kill line (guarded - preserves prefix) |

## How it Works

1. **Ctrl-X** toggles prefix mode on/off
2. When active, new prompts automatically start with the prefix
3. Guards prevent you from accidentally deleting or moving into the prefix
4. When you press Enter, the command is sent to `kimi -c "your command"`
5. If you type `✨ something` manually (without prefix mode), it still works via `fish_command_not_found`

## Requirements

- Fish shell 3.0+
- [Kimi CLI](https://github.com/MoonshotAI/kimi-cli) installed and in PATH
