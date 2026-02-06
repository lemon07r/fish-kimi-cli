# fish-kimi-cli key bindings
# Loaded automatically by fish from conf.d/

status is-interactive; or exit

# Source functions (conf.d loads before functions are autoloaded)
source (dirname (status -f))/../functions/kimi_cli.fish

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

# Backward word (Alt-B, Alt-Left)
bind \eb __kimi_cli_guard_backward_word
bind \e\[1\;3D __kimi_cli_guard_backward_word
bind -M insert \eb __kimi_cli_guard_backward_word 2>/dev/null
bind -M insert \e\[1\;3D __kimi_cli_guard_backward_word 2>/dev/null

# Home / Ctrl-A (improvement: prevents moving into prefix)
bind \e\[H __kimi_cli_guard_home
bind \ca __kimi_cli_guard_home
bind \e\[1~ __kimi_cli_guard_home  # Some terminals send this for Home
bind -M insert \e\[H __kimi_cli_guard_home 2>/dev/null
bind -M insert \ca __kimi_cli_guard_home 2>/dev/null
bind -M insert \e\[1~ __kimi_cli_guard_home 2>/dev/null

# Ctrl-U (kill line) - improvement: only kills content after prefix
bind \cu __kimi_cli_guard_kill_line
bind -M insert \cu __kimi_cli_guard_kill_line 2>/dev/null
