# .zshrc — interactive shells only.
# Layout: options -> history -> env -> keybindings -> completion -> tools -> plugins(LAST) -> aliases.
# Fast startup: reuse $HOMEBREW_PREFIX (no `brew --prefix`) and cache compinit.

# --- Shell options (navigation / globbing / misc) --------------------------
setopt auto_cd                 # `dirname` alone cd's into it
setopt auto_pushd              # cd pushes onto the dir stack
setopt pushd_ignore_dups       # no duplicate dir-stack entries
setopt pushd_silent            # don't print the stack on pushd
setopt extended_glob           # advanced glob operators (^ ~ #); set before any glob use
setopt interactive_comments    # allow `#` comments at the prompt
setopt no_beep                 # no terminal bell
unsetopt flow_control          # free Ctrl-S / Ctrl-Q

# --- History (files, sizes, behavior) --------------------------------------
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=1000000
export SAVEHIST=1000000
mkdir -p "${HISTFILE:h}"
setopt inc_append_history_time  # append each command to $HISTFILE after it finishes (records elapsed time; extended_history)
setopt extended_history         # also record start timestamp + elapsed time
setopt hist_ignore_dups         # skip a command identical to the previous one
setopt hist_ignore_space        # skip commands typed with a leading space (secrets)
setopt hist_reduce_blanks       # collapse superfluous whitespace before saving
setopt hist_verify              # on `!!` expansion, show it in the buffer before run

# --- Environment: relocate tool data to XDG (keep $HOME clean) --------------
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node/repl_history"
export PYTHON_HISTORY="$XDG_STATE_HOME/python/history"   # Python 3.13+
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"
export SQLITE_HISTORY="$XDG_CACHE_HOME/sqlite_history"
export VIMINIT='let $MYVIMRC="$XDG_CONFIG_HOME/vim/vimrc" | source $MYVIMRC'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
mkdir -p "${NODE_REPL_HISTORY:h}" "${PYTHON_HISTORY:h}"   # node/python won't create these dirs

# --- Keybindings & line editing (history: Ctrl-R/fzf and Up/Down) ----------
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}          # treat '/' as a word boundary

autoload -Uz edit-command-line        # edit the current line in $EDITOR (Ctrl-X Ctrl-E)
zle -N edit-command-line
bindkey '^X^E' edit-command-line
bindkey '^[[Z' reverse-menu-complete  # Shift-Tab: cycle completion backwards

# Home/End — bind both normal (^[[H/^[[F) and application (^[OH/^[OF) cursor modes.
bindkey '^[[H' beginning-of-line
bindkey '^[OH' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[OF' end-of-line

# --- Completion (cached compinit + zstyle styling) -------------------------
autoload -Uz compinit
_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"           # >24h old -> full regen (with security check)
else
  compinit -C -d "$_zcompdump"        # fresh enough -> skip the slow security check
fi
# Populate LS_COLORS from GNU dircolors -> colorized completion list and GNU ls.
command -v dircolors >/dev/null && eval "$(dircolors -b)"
zstyle ':completion:*' menu select                          # arrow-key menu selection
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colorize the candidate list
zstyle ':completion:*' group-name ''                        # group candidates by type
zstyle ':completion:*:descriptions' format '[%d]'           # group headers
zstyle ':completion:*' rehash true                          # pick up newly installed binaries
setopt complete_in_word always_to_end

# --- Tool init: runtime, prompt, dir-jump, fuzzy finder --------------------
# guarded with `command -v` so a bare machine (pre-install) doesn't error out
command -v mise     >/dev/null && eval "$(mise activate zsh)"
command -v starship >/dev/null && eval "$(starship init zsh)"
export _ZO_DATA_DIR="$XDG_DATA_HOME/zoxide"   # keep the zoxide db under XDG (not ~/Library/...)
export _ZO_MAXAGE=100000                      # remember more dirs before aging out (default 10000)
export _ZO_FZF_OPTS="--height=45% --layout=reverse --info=inline --border --exit-0 --select-1 --bind=ctrl-z:ignore,alt-up:preview-up,alt-down:preview-down,alt-page-up:preview-page-up,alt-page-down:preview-page-down --preview='eza --tree --level=2 --color=always --icons --group-directories-first {2..}' --preview-window=right,55%"
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
  # Ctrl+J opens the zoxide interactive picker (zi) and cd's to the choice.
  function _zi_widget() { local d; d="$(zoxide query -i)" && [[ -n "$d" ]] && builtin cd -- "$d"; zle reset-prompt; }
  zle -N _zi_widget
  bindkey '^J' _zi_widget
fi

# fzf: list with fd (fast, respects .gitignore); preview with bat/eza
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border --info inline'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :200 {}'"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"
command -v fzf >/dev/null && source <(fzf --zsh)   # fzf >= 0.48 emits keys + completion

# --- Plugins: source directly (no plugin manager); brew(mac)/git clone(Linux) -
# Required order: autosuggestions -> syntax-highlighting -> history-substring-search.
# Each block is silently skipped if the plugin is not installed yet.
# autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)   # suggest from history, then completion
ZSH_AUTOSUGGEST_MANUAL_REBIND=1                 # bind widgets once (small perf win)
for _f in \
  "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  [[ -r "$_f" ]] && { source "$_f"; break; }
done

# syntax-highlighting (wraps ZLE, so it loads after other widgets)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)      # also match bracket pairs
for _f in \
  "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  [[ -r "$_f" ]] && { source "$_f"; break; }
done

# history-substring-search (MUST load after syntax-highlighting; Up/Down prefix search)
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1        # skip duplicate matches
for _f in \
  "$HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh" \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"; do
  [[ -r "$_f" ]] && {
    source "$_f"
    # Up/Down for both normal (^[[A/^[[B) and application (^[OA/^[OB) cursor modes.
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OB' history-substring-search-down
    break
  }
done

# --- Aliases (kept in a separate file for readability) ---------------------
[[ -r "$ZDOTDIR/aliases.zsh" ]] && source "$ZDOTDIR/aliases.zsh"

unset _f _zcompdump
