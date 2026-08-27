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

# --- MulmoTerminal: which servers are running right now ---------------------
# Each live server registers itself as ~/.mulmoterminal/instances/<pid>.json
# ({pid, port, startedAt}) and removes the file on exit. There is no CLI for
# reading it back, hence this.
# A crash cannot clean up after itself, so an entry is only a claim — `kill -0`
# (existence/permission check, delivers no signal) is what confirms it. Stale
# entries are read past, not pruned; MulmoTerminal drops them itself the next
# time it reads the directory.
# The timestamp goes through jq rather than `date` because this repo installs
# GNU coreutils on macOS, where `date -r` means "reference file" rather than
# BSD's "seconds since epoch" — the same command would print nothing there.
if command -v jq >/dev/null; then
  mulmops() {
    local dir="$HOME/.mulmoterminal/instances" pid port started found=0
    if [[ -d $dir ]]; then
      while IFS=$'\t' read -r pid port started; do
        kill -0 "$pid" 2>/dev/null || continue
        printf 'pid=%-7s http://localhost:%-6s up since %s\n' "$pid" "$port" "$started"
        found=1
      done < <(
        find "$dir" -maxdepth 1 -name '*.json' -exec jq -r '
          "\(.pid)\t\(.port // "?")\t\(.startedAt/1000|localtime|strftime("%Y-%m-%d %H:%M:%S"))"
        ' {} + 2>/dev/null
      )
    fi
    (( found )) || print "mulmops: no MulmoTerminal server is running"
  }
fi
