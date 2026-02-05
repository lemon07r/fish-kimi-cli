# fish-kimi-cli key bindings
# Loaded automatically by fish from conf.d/

status is-interactive; or exit

# Ctrl-X toggles prefix mode
bind \cx __kimi_cli_toggle
bind -M insert \cx __kimi_cli_toggle 2>/dev/null

# Backspace (both \b and DEL)
bind \b __kimi_cli_guard_delete
bind \177 __kimi_cli_guard_delete
bind -M insert \b __kimi_cli_guard_delete 2>/dev/null
bind -M insert \177 __kimi_cli_guard_delete 2>/dev/null

# Ctrl-W (backward kill word)
bind \cw __kimi_cli_guard_kill_word
bind -M insert \cw __kimi_cli_guard_kill_word 2>/dev/null

# Left arrow / Ctrl-B (improvement: prevents moving into prefix)
bind \e\[D __kimi_cli_guard_left
bind \cb __kimi_cli_guard_left
bind -M insert \e\[D __kimi_cli_guard_left 2>/dev/null
bind -M insert \cb __kimi_cli_guard_left 2>/dev/null

# Home / Ctrl-A (improvement: prevents moving into prefix)
bind \e\[H __kimi_cli_guard_home
bind \ca __kimi_cli_guard_home
bind -M insert \e\[H __kimi_cli_guard_home 2>/dev/null
bind -M insert \ca __kimi_cli_guard_home 2>/dev/null
