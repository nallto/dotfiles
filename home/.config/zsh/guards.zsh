# guards.zsh — interactive tripwires that enforce this repo's "one home per
# thing" rules at the prompt. These are functions, so they exist ONLY in
# interactive shells; scripts and CI pass through untouched. To bypass a guard
# on purpose, prefix the command with `command` (e.g. `command npm i -g foo`) —
# `command` skips shell functions and runs the real binary. (A leading backslash
# escapes aliases but NOT functions, so `\npm` does not bypass these.)

# Visible, colored notice on stderr.  $1=color  $2=label  $3=hint
_guard() { print -u2 -P "%B%F{$1}$2%f%b — $3"; }

# npm: block global installs. Persistent CLI -> mise / `uv tool install` /
# pnpm(corepack); one-off -> npx.
npm() {
  if [[ "$1" == (install|i|add|in) ]]; then
    local a
    for a in "$@"; do
      if [[ "$a" == (-g|--global|--location=global) ]]; then
        _guard red "🚫 npm -g blocked" "persistent CLI -> mise / 'uv tool install' / pnpm(corepack); one-off -> npx. Prefix 'command' to override."
        return 1
      fi
    done
  fi
  command npm "$@"
}

# pnpm: block global installs. Persistent CLI -> mise / uv tool; one-off -> pnpm dlx.
pnpm() {
  if [[ "$1" == (add|install|i) ]]; then
    local a
    for a in "$@"; do
      if [[ "$a" == (-g|--global) ]]; then
        _guard red "🚫 pnpm -g blocked" "persistent CLI -> mise / uv tool; one-off -> 'pnpm dlx'. Prefix 'command' to override."
        return 1
      fi
    done
  fi
  command pnpm "$@"
}

# yarn: not used here (pnpm via corepack is the default).
yarn() {
  _guard red "🚫 yarn is not used here" "this env uses pnpm(corepack). Prefix 'command' if you really need yarn."
  return 1
}

# brew: warn only. The tracked home is the Brewfile (`brew bundle`), but manual
# installs happen — let it proceed and just remind.
brew() {
  if [[ "$1" == (install|uninstall|remove|rm) ]]; then
    _guard yellow "⚠️ brew $1 should go through the Brewfile" "proceeding; add it to the Brewfile later and manage via 'brew bundle'."
  fi
  command brew "$@"
}

# pip / pip3: python is owned by uv. Warn on installs OUTSIDE a venv (inside a
# venv pip is legitimate -> stay silent). Proceed either way.
_pip_guard() {
  local mgr=$1
  shift
  if [[ "$1" == install && -z "$VIRTUAL_ENV" ]]; then
    _guard yellow "⚠️ $mgr install outside a venv" "CLIs -> 'uv tool install'; deps -> inside a uv/venv. Proceeding."
  fi
  command "$mgr" "$@"
}
pip() { _pip_guard pip "$@"; }
pip3() { _pip_guard pip3 "$@"; }

# mise: block `mise use -g python` (python is uv's, never mise's). Preserve
# mise's activation shim (defined earlier by `mise activate zsh`) for everything
# else by copying it aside and delegating to it.
if (( $+functions[mise] )); then
  functions -c mise _mise_activated
  mise() {
    if [[ "$1" == use ]]; then
      local has_g=0 has_py=0 a
      for a in "$@"; do
        [[ "$a" == (-g|--global) ]] && has_g=1
        [[ "$a" == (python|python@*) ]] && has_py=1
      done
      if (( has_g && has_py )); then
        _guard red "🚫 mise use -g python blocked" "python is owned by uv; use 'uv python install'. Prefix 'command' to override."
        return 1
      fi
    fi
    _mise_activated "$@"
  }
fi
