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
# - Better guard coverage (left arrow, home, Ctrl-U, etc.)
# - Status function for prompt integration
# - Cleaner implementation using fish idioms

# Configuration - matching zsh plugin defaults
set -q __kimi_cli_prefix_char; or set -g __kimi_cli_prefix_char "✨"
set -q __kimi_cli_prefix; or set -g __kimi_cli_prefix "$__kimi_cli_prefix_char "
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
# We use fish_postexec to set up the next command line
function __kimi_cli_postexec --on-event fish_postexec
    test $__kimi_cli_active -eq 1; or return
    # Schedule prefix injection after prompt is drawn
    # fish doesn't have a direct equivalent to zle-line-init,
    # but we can use commandline in fish_prompt
end

# Called after prompt is displayed to inject prefix
function __kimi_cli_inject_prefix --on-event fish_prompt
    test $__kimi_cli_active -eq 1; or return
    # Only inject if buffer is empty (new prompt)
    test -z (commandline); or return
    set -l prefix "$__kimi_cli_prefix"
    commandline -r -- "$prefix"
    commandline -C (string length -- "$prefix")
end

# Guard: Backspace (matching zsh backward-delete-char guard)
function __kimi_cli_guard_delete
    __kimi_cli_enforce_cursor
    if test $__kimi_cli_active -ne 1
        commandline -f backward-delete-char
        return
    end

    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        if test (commandline -C) -le $prefix_len
            printf "\a" >&2
            return
        end
    end
    commandline -f backward-delete-char
end

# Guard: Ctrl-W (matching zsh backward-kill-word guard)
function __kimi_cli_guard_kill_word
    __kimi_cli_enforce_cursor
    if test $__kimi_cli_active -ne 1
        commandline -f backward-kill-word
        return
    end

    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        if test (commandline -C) -le $prefix_len
            printf "\a" >&2
            return
        end
    end
    commandline -f backward-kill-word
    __kimi_cli_enforce_cursor
end

# Guard: Left arrow (improvement over zsh - prevents moving into prefix)
function __kimi_cli_guard_left
    __kimi_cli_enforce_cursor
    if test $__kimi_cli_active -ne 1
        commandline -f backward-char
        return
    end

    if __kimi_cli_has_prefix
        set -l prefix_len (__kimi_cli_prefix_len)
        if test (commandline -C) -le $prefix_len
            printf "\a" >&2
            return
        end
    end
    commandline -f backward-char
end

# Guard: Backward word (improvement - prevents moving into prefix)
function __kimi_cli_guard_backward_word
    __kimi_cli_enforce_cursor
    if test $__kimi_cli_active -ne 1
        commandline -f backward-word
        return
    end

    commandline -f backward-word
    __kimi_cli_enforce_cursor
end

# Guard: Home / Ctrl-A (improvement over zsh - prevents moving into prefix)
function __kimi_cli_guard_home
    if test $__kimi_cli_active -ne 1
        commandline -f beginning-of-line
        return
    end

    if __kimi_cli_has_prefix
        commandline -C (__kimi_cli_prefix_len)
    else
        commandline -f beginning-of-line
    end
end

# Guard: Ctrl-U (kill line) - improvement: only kill content after prefix
function __kimi_cli_guard_kill_line
    if test $__kimi_cli_active -ne 1
        commandline -f backward-kill-line
        return
    end

    if __kimi_cli_has_prefix
        set -l prefix "$__kimi_cli_prefix"
        commandline -r -- "$prefix"
        commandline -C (string length -- "$prefix")
    else
        commandline -f backward-kill-line
    end
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

# Command not found handler - fallback to kimi (matching zsh behavior)
# Preserves any existing handler
if functions -q __kimi_cli_original_command_not_found
    # Already wrapped, skip
else if functions -q fish_command_not_found
    # Save original handler
    functions -c fish_command_not_found __kimi_cli_original_command_not_found
end

function fish_command_not_found
    set -l cmd $argv[1]
    set -l args $argv[2..-1]

    if test -z "$cmd"
        if functions -q __kimi_cli_original_command_not_found
            __kimi_cli_original_command_not_found $argv
            return $status
        end
        return 127
    end

    set -l prefix_char "$__kimi_cli_prefix_char"
    set -l effective_cmd

    if test "$cmd" = "$prefix_char"
        # Command is just the prefix char, rest are args
        set effective_cmd $args
    else if string match -q -- "$prefix_char*" "$cmd"
        # Command starts with prefix char
        set -l stripped (string replace -- "$prefix_char" "" -- "$cmd")
        if test -n "$stripped"
            set effective_cmd $stripped $args
        else
            set effective_cmd $args
        end
    else
        # Not a kimi-cli prefixed command, delegate to original handler
        if functions -q __kimi_cli_original_command_not_found
            __kimi_cli_original_command_not_found $argv
            return $status
        end
        printf "fish: Unknown command: %s\n" "$cmd" >&2
        return 127
    end

    if test (count $effective_cmd) -eq 0
        printf "kimi-cli: nothing to run after '%s'.\n" "$prefix_char" >&2
        return 127
    end

    if not command -q kimi
        if functions -q __kimi_cli_original_command_not_found
            __kimi_cli_original_command_not_found $argv
            return $status
        end
        printf "kimi: command not found; unable to handle '%s'.\n" "$effective_cmd[1]" >&2
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
