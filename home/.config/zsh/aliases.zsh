# aliases.zsh — sourced from .zshrc. Interactive aliases only.

# --- Listing: eza (modern ls). Same binary on macOS/Linux = identical UX. ---
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza --group-directories-first -l --git'          # long + git status
  alias la='eza --group-directories-first -l --git -a'       # long + hidden
  alias lt='eza --tree --group-directories-first'            # full tree (use ltN to cap depth)
  alias lta='eza --tree -a --group-directories-first'        # full tree + hidden
  alias l='la'                                               # shortest listing

  # Tree at an explicit depth (revives the old lv/llv numeric-level trick):
  #   lt1..lt9   = tree N levels deep
  #   lta1..lta9 = same, including hidden files
  for _n in {1..9}; do
    alias "lt$_n"="eza --tree --level=$_n --group-directories-first"
    alias "lta$_n"="eza --tree --level=$_n -a --group-directories-first"
  done
  unset _n
fi

# --- File viewing: bat (syntax-highlighted cat; plain when piped) -----------
command -v bat >/dev/null && alias cat='bat --paging=never'

# --- ghq: fuzzy-jump between repositories (ghq list -> fzf -> cd) -----------
if command -v ghq >/dev/null && command -v fzf >/dev/null; then
  cdr() { local d; d=$(ghq list | fzf) && cd "$(ghq root)/$d" || return; }
fi

# --- Convenience -----------------------------------------------------------
alias mkdir='mkdir -p'   # create parent dirs as needed
alias reload='exec zsh'  # reload the shell (re-read all startup files)

# --- WSL2: bridge clipboard to Windows via absolute System32 paths, so it works even with
#     appendWindowsPath=false (no dependency on the Windows PATH bleeding into WSL) ---
if [[ "$OSTYPE" == linux* ]]; then
  [[ -x /mnt/c/Windows/System32/clip.exe ]] && \
    alias pbcopy='/mnt/c/Windows/System32/clip.exe'
  [[ -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ]] && \
    alias pbpaste='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -command "Get-Clipboard"'
fi
