# functions.zsh — sourced from .zshrc. Interactive shell functions only.

# --- ghq: fuzzy-jump between repositories (ghq list -> fzf -> cd) -----------
if command -v ghq >/dev/null && command -v fzf >/dev/null; then
  cdr() { local d; d=$(ghq list | fzf) && cd "$(ghq root)/$d" || return; }
fi

# --- git worktree: fuzzy-jump between worktrees (branch + path) -------------
if command -v git >/dev/null && command -v fzf >/dev/null; then
  cdw() {
    local list selection
    list=$(
      git worktree list --porcelain 2>/dev/null | awk '
        /^worktree / { path = substr($0, 10) }
        /^branch /   { ref = substr($0, 8); sub(/^refs\/heads\//, "", ref) }
        /^detached$/ { ref = "(detached)" }
        /^bare$/     { ref = "(bare)" }
        /^$/         { if (path != "") printf "%s\t%s\n", ref, path; path = ""; ref = "" }
        END          { if (path != "") printf "%s\t%s\n", ref, path }
      '
    )
    [[ -z $list ]] && {
      print -u2 "cdw: not inside a git repository"
      return 1
    }

    selection=$(
      printf '%s\n' "$list" |
        fzf --height 60% --reverse \
          --delimiter=$'\t' \
          --with-nth=1 \
          --preview 'printf "path: %s\n\n" {2}; git -C {2} log -1 --format="last: %h %ar %s" 2>/dev/null; printf "\n"; git -C {2} status --short --branch 2>/dev/null | head -30' \
          --preview-window 'right,70%'
    ) || return
    [[ -z $selection ]] && return

    cd "${selection#*$'\t'}"
  }
fi
