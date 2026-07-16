# ~/.zshenv — MUST live at $HOME. It bootstraps ZDOTDIR and is read by EVERY zsh
# (interactive, non-interactive, scripts, subshells). Keep it declarative: no side
# effects (no mkdir, no process-spawning command substitution).

# XDG Base Directory layout — keep $HOME clean.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Runtime dir: Linux/systemd sets XDG_RUNTIME_DIR (/run/user/$UID) — respect it.
# Fall back to a $TMPDIR-based path only when unset (macOS, systemd-less Linux).
# The fallback directory is created once at login in .zprofile (side effect).
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-${${TMPDIR:-/tmp}%/}/xdg-$UID}"

# Redirect tools that don't honor XDG on their own (declarative; needed in scripts too).
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"       # aws CLI otherwise reads ~/.aws/config
export COPILOT_HOME="$XDG_CONFIG_HOME/copilot"             # GitHub Copilot CLI otherwise uses ~/.copilot
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"              # npm cache (otherwise ~/.npm)
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"  # npm user config (otherwise ~/.npmrc)

# macOS: stop Apple's per-window shell-session saving (~/.zsh_sessions clutter).
# Harmless on Linux (the variable is simply ignored there).
export SHELL_SESSIONS_DISABLE=1

# Point zsh at ~/.config/zsh for the rest of its startup files.
# Chicken-and-egg: zsh reads $HOME/.zshenv first (ZDOTDIR still unset), and only
# here do we set ZDOTDIR — so this file itself cannot live under ZDOTDIR.
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
