# fish-kimi-cli - Fish port of zsh-kimi-cli with improvements
# https://github.com/MoonshotAI/zsh-kimi-cli
#
# Core features (matching zsh plugin):
# - Ctrl-X toggles prefix mode (adds/removes prefix from current line)
# - When prefix mode active, new prompts start with prefix
# - Guards prevent deleting/moving cursor into the prefix
# - Fallback: if prefix typed manually and command not found, sends to kimi
#
# Improvements over zsh version:
# - Better guard coverage (left arrow, home, etc)
# - Status function for prompt integration
# - Cleaner implementation using fish idioms

# Configuration - matching zsh plugin defaults
set -q __kimi_cli_prefix; or set -g __kimi_cli_prefix "✨ "
set -q __kimi_cli_active; or set -g __kimi_cli_active 0

# Helper: Get prefix length
function __kimi_cli_prefix_len
    string length -- "$__kimi_cli_prefix"
end

# Helper: Check if buffer starts with prefix
function __kimi_cli_has_prefix
    string match -q -- "$__kimi_cli_prefix*" (commandline)
end

# Helper: Enforce cursor position (keep it after prefix)
function __kimi_cli_enforce_cursor
    test $__kimi_cli_active -eq 1; or return
    __kimi_cli_has_prefix; or return
    
    set -l prefix_len (__kimi_cli_prefix_len)
    set -l cursor (commandline -C)
    
    if test $cursor -lt $prefix_len
        commandline -C $prefix_len
    end
end

# Toggle prefix mode with Ctrl-X (matching zsh behavior)
function __kimi_cli_toggle
    set -l prefix "$__kimi_cli_prefix"
    set -l prefix_len (__kimi_cli_prefix_len)
    set -l buffer (commandline)
    set -l cursor (commandline -C)
    
    if string match -q -- "$prefix*" "$buffer"
        # Remove prefix
        commandline -r -- (string sub -s (math $prefix_len + 1) -- "$buffer")
        set -l new_cursor (math $cursor - $prefix_len)
        test $new_cursor -lt 0; and set new_cursor 0
        commandline -C $new_cursor
        set -g __kimi_cli_active 0
    else
        # Add prefix
        commandline -r -- "$prefix$buffer"
        commandline -C (math $cursor + $prefix_len)
        set -g __kimi_cli_active 1
    end
end

# On new prompt, add prefix if mode is active (zle-line-init equivalent)
function __kimi_cli_prompt_init --on-event fish_prompt
    test $__kimi_cli_active -eq 1; or return
    set -l prefix "$__kimi_cli_prefix"
    commandline -r -- "$prefix"
    commandline -C (string length -- "$prefix")
end

# Guard: Backspace (matching zsh backward-delete-char guard)
function __kimi_cli_guard_delete
    __kimi_cli_enforce_cursor
    test $__kimi_cli_active -ne 1; and commandline -f backward-delete-char; and return
    
    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        test (commandline -C) -le $prefix_len; and printf "\a" >&2; and return
    end
    commandline -f backward-delete-char
end

# Guard: Ctrl-W (matching zsh backward-kill-word guard)
function __kimi_cli_guard_kill_word
    __kimi_cli_enforce_cursor
    test $__kimi_cli_active -ne 1; and commandline -f backward-kill-word; and return
    
    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        test (commandline -C) -le $prefix_len; and printf "\a" >&2; and return
    end
    commandline -f backward-kill-word
    __kimi_cli_enforce_cursor
end

# Guard: Left arrow (improvement over zsh - prevents moving into prefix)
function __kimi_cli_guard_left
    __kimi_cli_enforce_cursor
    test $__kimi_cli_active -ne 1; and commandline -f backward-char; and return
    
    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        test (commandline -C) -le $prefix_len; and printf "\a" >&2; and return
    end
    commandline -f backward-char
end

# Guard: Home / Ctrl-A (improvement over zsh - prevents moving into prefix)
function __kimi_cli_guard_home
    test $__kimi_cli_active -ne 1; and commandline -f beginning-of-line; and return
    
    if __kimi_cli_has_prefix
        commandline -C (__kimi_cli_prefix_len)
    else
        commandline -f beginning-of-line
    end
end

# Command not found handler - fallback to kimi (matching zsh behavior)
function fish_command_not_found
    set -l cmd $argv[1]
    set -l args $argv[2..-1]
    
    test -z "$cmd"; and return 127
    
    # Check if command starts with our prefix (the part before the space)
    set -l prefix_char (string match -r '^\S+' -- "$__kimi_cli_prefix")
    
    if test "$cmd" = "$prefix_char"
        set -l effective_cmd $args
    else if string match -q -- "$prefix_char*" "$cmd"
        set -l stripped (string replace -- "$prefix_char" "" -- "$cmd")
        set -l effective_cmd $stripped $args
    else
        printf "fish: Unknown command: %s\n" "$cmd" >&2
        return 127
    end
    
    if test (count $effective_cmd) -eq 0
        printf "kimi-cli: nothing to run after '%s'\n" "$prefix" >&2
        return 127
    end
    
    if not command -q kimi
        printf "kimi: command not found\n" >&2
        return 127
    end
    
    # Build escaped command string
    set -l escaped_cmd
    for arg in $effective_cmd
        set escaped_cmd $escaped_cmd (string escape -- $arg)
    end
    
    kimi -c (string join " " $escaped_cmd)
    return $status
end

# IMPROVEMENT: Status function for prompt integration
# Returns 0 if prefix mode is active, 1 otherwise
# Usage in prompt: if __kimi_cli_status -q; echo "[KIMI]"; end
function __kimi_cli_status
    if test $__kimi_cli_active -eq 1
        if contains -- -q $argv
            return 0
        end
        echo "kimi-cli: prefix mode is active"
        echo "kimi-cli: prefix: '$__kimi_cli_prefix'"
        return 0
    else
        if contains -- -q $argv
            return 1
        end
        echo "kimi-cli: prefix mode is inactive"
        echo "kimi-cli: prefix: '$__kimi_cli_prefix'"
        return 1
    end
end
