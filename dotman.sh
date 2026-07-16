#!/usr/bin/env bash
#
# dotman.sh — symlink-based dotfiles manager (install / uninstall / clean)
#
# Single-mirror layout (v19):
#   The repo's `home/` tree mirrors $HOME.
#     home/.zshenv             -> ~/.zshenv
#     home/.config/zsh/.zshrc  -> ~/.config/zsh/.zshrc
#   The mapping is a single rule: "mirror the contents of home/ into $HOME".
#
set -euo pipefail

# --- Locate the repository and its source tree ----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"   # overridable for tests / unusual invocation
SRC="$DOTFILES_DIR/home"

# --- Options --------------------------------------------------------------
ACTION=""          # install | uninstall
DO_CLEAN=false
DRY_RUN=false
FORCE=false
EXECUTE=false      # false = show plan / true = apply (two-phase, shared logic)

usage() {
  cat <<'EOF'
dotman.sh — symlink-based dotfiles manager (single-mirror: home/ -> $HOME)

Usage:
  ./dotman.sh -i            Install (show plan -> confirm [y/N] -> apply)
  ./dotman.sh -i --dry-run  Show the plan only (make no changes)
  ./dotman.sh -i --force    Install without the confirmation prompt
  ./dotman.sh -u            Uninstall (remove only the symlinks we created)
  ./dotman.sh --clean       Remove dangling links that point into this repo

Options:
  -i, --install     Link home/* into $HOME
  -u, --uninstall   Remove links previously created from home/*
      --clean       Remove broken links pointing into DOTFILES_DIR
      --dry-run     Print the plan without applying it
      --force       Skip the confirmation prompt
  -h, --help        Show this help

Environment:
  DOTFILES_DIR      Path to the repo (default: this script's own directory)

Secrets (*.local, id_*, *.pem, *.key) are never linked.
EOF
  exit "${1:-0}"
}

log() { printf '%s\n' "$*"; }

# Timestamp used for backup filenames
ts() { date +%Y%m%d%H%M%S; }

# --- Place a single file (plan or apply, depending on $EXECUTE) ------------
place() {
  local src="$1" target="$2" dir
  dir="$(dirname "$target")"

  # Ensure the parent directory exists as a real dir (we never link directories)
  if [ ! -d "$dir" ]; then
    if $EXECUTE; then mkdir -p "$dir"; else log "  mkdir -p   $dir"; fi
  fi

  if [ -L "$target" ]; then
    # Target is already a symlink
    local cur; cur="$(readlink "$target")"
    if [ "$cur" = "$src" ]; then
      log "  ok(skip)   $target"           # already correct -> idempotent skip
      return 0
    fi
    # Symlink points elsewhere -> back it up, then relink
    if $EXECUTE; then
      mv "$target" "$target.bak.$(ts)"
      ln -sn "$src" "$target"
    else
      log "  relink     $target  (was -> $cur; will back up first)"
    fi
    return 0
  fi

  if [ -e "$target" ]; then
    # A real file/dir exists -> back it up, then link (never overwrite silently)
    if $EXECUTE; then
      mv "$target" "$target.bak.$(ts)"
      ln -sn "$src" "$target"
    else
      log "  backup+ln  $target  (real file -> .bak.<timestamp>)"
    fi
    return 0
  fi

  # Nothing there -> create the link
  if $EXECUTE; then ln -sn "$src" "$target"; else log "  ln -sn     $src -> $target"; fi
}

# --- Walk every file under home/ (secrets are excluded) --------------------
each_src_file() {
  # Exclude secrets / machine-local files defensively
  find "$SRC" -type f \
    ! -name '*.local' ! -name 'id_*' ! -name '*.pem' ! -name '*.key' \
    -print0
}

install_all() {
  [ -d "$SRC" ] || { log "Source tree not found: $SRC"; exit 1; }
  each_src_file | while IFS= read -r -d '' f; do
    place "$f" "$HOME/${f#"$SRC"/}"
  done
}

uninstall_all() {
  [ -d "$SRC" ] || { log "Source tree not found: $SRC"; exit 1; }
  each_src_file | while IFS= read -r -d '' f; do
    local target="$HOME/${f#"$SRC"/}"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$f" ]; then
      if $EXECUTE; then rm "$target"; else log "  rm         $target"; fi
    fi
  done
}

# Remove broken links (pointing into this repo but whose source is gone)
clean_all() {
  find "$HOME" -maxdepth 4 -type l 2>/dev/null | while IFS= read -r l; do
    local tgt; tgt="$(readlink "$l")"
    case "$tgt" in
      "$DOTFILES_DIR"/*)
        if [ ! -e "$l" ]; then   # -e follows the link -> false for a broken link
          if $EXECUTE; then rm "$l"; else log "  rm(dangle) $l"; fi
        fi ;;
    esac
  done
}

run_selected() {
  $DO_CLEAN && clean_all
  case "$ACTION" in
    install)   install_all ;;
    uninstall) uninstall_all ;;
  esac
}

# --- Parse arguments ------------------------------------------------------
[ $# -eq 0 ] && usage 1
while [ $# -gt 0 ]; do
  case "$1" in
    -i|--install)   ACTION="install" ;;
    -u|--uninstall) ACTION="uninstall" ;;
    --clean)        DO_CLEAN=true ;;
    --dry-run)      DRY_RUN=true ;;
    --force)        FORCE=true ;;
    -h|--help)      usage 0 ;;
    *) log "Unknown option: $1"; usage 1 ;;
  esac
  shift
done
[ -n "$ACTION" ] || $DO_CLEAN || { log "No action given (-i / -u / --clean)"; usage 1; }

# --- Phase 1: show the plan -----------------------------------------------
EXECUTE=false
log "== plan (DOTFILES_DIR=$DOTFILES_DIR, HOME=$HOME) =="
run_selected

# --dry-run stops here
$DRY_RUN && { log "== dry-run: no changes =="; exit 0; }

# --- Confirmation ---------------------------------------------------------
if ! $FORCE; then
  printf 'Apply the changes above? [y/N] '
  read -r ans || ans=""
  case "$ans" in
    y|Y|yes|YES) ;;
    *) log "Aborted."; exit 0 ;;
  esac
fi

# --- Phase 2: apply -------------------------------------------------------
EXECUTE=true
log "== apply =="
run_selected
log "== done =="
