# .zprofile — login shells only. Runs AFTER /etc/zprofile (which runs path_helper).
# Putting Homebrew init here (not in .zshenv) lets brew win the PATH order, because
# macOS's /etc/zprofile reorders PATH via path_helper BEFORE this user file runs.

if [[ "$OSTYPE" == darwin* ]]; then
  # --- macOS: Homebrew (mac only) ---
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"   # exports HOMEBREW_PREFIX, PATH, MANPATH, ...
  fi

  # Point `brew bundle` at this repo's Brewfile WITHOUT hardcoding a path: this file is
  # a symlink from the repo, so resolve it and strip the known suffix to find the root.
  _zprofile_real="${${(%):-%x}:A}"
  _dotfiles_root="${_zprofile_real%/home/.config/zsh/.zprofile}"
  [[ -f "$_dotfiles_root/Brewfile" ]] && export HOMEBREW_BUNDLE_FILE="$_dotfiles_root/Brewfile"
  unset _zprofile_real _dotfiles_root

  # GNU coreutils parity — macOS ONLY (Linux is already GNU). For SCRIPT parity only;
  # interactive use relies on modern replacements (eza/bat/rg/fd), not GNU overrides.
  # (N) = zsh null-glob: the loop is a no-op (no error) before GNU tools are installed.
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    for d in "$HOMEBREW_PREFIX"/opt/*/libexec/gnubin(N); do PATH="$d:$PATH"; done
    for d in "$HOMEBREW_PREFIX"/opt/*/libexec/gnuman(N); do MANPATH="$d:$MANPATH"; done
    export PATH MANPATH
  fi
fi

# Create the XDG runtime dir once per login if missing (side effect kept out of
# .zshenv). On Linux/systemd it already exists (/run/user/$UID) and is left as-is;
# this only materializes the $TMPDIR fallback (macOS, systemd-less Linux).
if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
  mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
fi

# Both OSes: put ~/.local/bin on PATH — unconditionally (even before it exists), so a
# `uv tool install`'d CLI is found the moment uv creates it. The case guard just avoids
# adding a duplicate entry if this file is re-sourced.
#   macOS → `uv tool install` places Python CLIs (ruff, ty, ...) in ~/.local/bin
#   Linux → mise's official installer + uv tools also live in ~/.local/bin
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
export PATH
