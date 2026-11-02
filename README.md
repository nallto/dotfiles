# dotfiles

An endless dotfiles journey

## Setup
`./bootstrap.sh` (dotman → `brew bundle` → mise / corepack / uv)

## Machine-local packages (macOS)
Packages you don't want in the public `Brewfile` go in `Brewfile.local` next to it, written in
the same Brewfile syntax (e.g. `cask "some-app"`). It is gitignored, and `Brewfile` loads it, so
a plain `brew bundle` installs both and `brew bundle cleanup` treats them as one list.
Edit it by hand: `brew bundle add` / `remove` without `--file` change the public `Brewfile`,
and `brew bundle dump --force` would overwrite the line that loads `Brewfile.local`.

## Placement (single-mirror tree)
`./dotman.sh --help` — placement options (dry-run / uninstall / clean)

## launchd agents (macOS)
`launchman --help` — register / list / start / stop this user's launch agents.
`register` symlinks a plist into `~/Library/LaunchAgents` and bootstraps it, so the
agent stays accountable to the file it came from.
