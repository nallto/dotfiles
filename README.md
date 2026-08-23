# dotfiles

An endless dotfiles journey

## Setup
`./bootstrap.sh` (dotman → `brew bundle` → mise / corepack / uv)

## Placement (single-mirror tree)
`./dotman.sh --help` — placement options (dry-run / uninstall / clean)

## launchd agents (macOS)
`launchman --help` — register / list / start / stop this user's launch agents.
`register` symlinks a plist into `~/Library/LaunchAgents` and bootstraps it, so the
agent stays accountable to the file it came from.
