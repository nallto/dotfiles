# Project conventions — dotfiles

Personal dotfiles shared across macOS + Linux (WSL2 / DevContainer).
Concept: **"always able to account for where each installed thing came from."**
This file is the single source of truth for these conventions — the ground rules to follow every session.

> Principle: **don't write down what a machine can enforce.** Enforcement lives in
> `.gitignore` / `make check` / GitHub Actions (those are authoritative). Keep this file to
> the non-obvious rules and the reasons behind them.

## Verification (most important)
- Before any completion report, run `make check` and confirm it is green. Work that isn't green is not "done."
- `make check` is identical to CI (shellcheck + `taplo fmt --check`/lint + `bash -n`/`zsh -n`).
- See `make help` for the available targets. If shellcheck is missing, install it with `brew bundle`.

## Absolute rules (violating these breaks the design)
1. **Never commit secrets.** SSH keys, credentials, and tokens stay out of the dotfiles (public keys too).
   Generate them per-machine and keep the reproduction steps in `local/*-setup.md` (private). `.gitignore` enforces this structurally.
2. **One home per thing:** one tool = one manager per OS. Never install the same thing from two places.
3. **The real code is the source of truth for where things live** (`Brewfile` / mise `config.toml` + `conf.d` / `linux/apt-packages.txt`).
   The "homes" section below is a human-readable summary of it; if they disagree, the code wins and the summary gets fixed.
4. **Secret files (`*.local`, keys) are outside dotman's scope.**

## Where packages / runtimes live
- node itself = **mise only** (never brew's node).
- python itself = **uv only** (never `mise use -g python`; leave the system `/usr/bin/python3` untouched).
- pnpm = **corepack** (never `npm i -g pnpm`).
- Python CLIs (ruff, ty, etc.) = **`uv tool install`** (not pipx, not brew).
- Shared-config CLIs (eza/bat/fd/ripgrep/fzf/delta/starship/zoxide) = **mac: brew / Linux: mise**.
  When adding one, reflect it in **both** the Brewfile and the mise config.
- One-off CLIs (jq/gh/ghq/vim/tig/cloc, etc.) = **mac: brew / Linux: apt** (mise if apt lacks it).
- **The Brewfile is mac-only.** Linux uses apt + mise.
- **Never run `brew install X` directly** → edit the Brewfile → `brew bundle`.

## Shell file placement rules
- **`.zshenv` must live at `$HOME`** (the one file that bootstraps ZDOTDIR). All other zsh config goes under `~/.config/zsh/`.
- No side effects (mkdir, etc.) in `.zshenv`. Homebrew init goes in `.zprofile` (to beat `path_helper`).
- Handle OS differences inline via runtime branching (`[[ $OSTYPE == darwin* ]]`). No `ostype-*/` split folders (double maintenance).

## Multiple accounts
- Always clone via the Host alias: `ghq get git@gh-<label>:owner/repo.git`.
- ghq root is `~/repos` (set as `ghq.root` in git config), not `~/ghq`. Jump between clones with the `cdr` shell function (`ghq list | fzf`).

## Where knowledge goes
The moment you think "another me / another AI should know this," write it into a Git-tracked file (auto memory is personal-local and not shared).

| Kind of knowledge | Where it goes |
|---|---|
| Personal, ephemeral notes / your own reminders | Claude auto memory (not committed) |
| Durable conventions for humans + AI | this file |
| Secret reproduction steps (keys / auth) | `local/*-setup.md` (private, gitignored) |
| User-facing setup / usage | `README.md` |
| Snapshots of app-written config | `reference/<app>/` (each with a README) |

- Invariant: **keep docs, code, and config consistent in the same change** — don't let them drift and reconcile later.

## Commits and PRs
- Commit messages follow **Conventional Commits** (e.g. `feat(reference): ...`).

## How AI agents should work
- For non-trivial changes, present a plan first (what changes, the steps, how you'll verify, trade-offs) and get approval before acting.
- When you spot room to improve a convention, config, or doc, **propose it — don't just change it.**
- Never read, write, or commit secrets (`.env`, keys, tokens) — `.gitignore` enforces it, but hold the line as discipline too.
- Rough implementation order: **dotman → config files → bootstrap → auth.**

## dotman.sh
Idempotent; backs up real files to `*.bak.<timestamp>` before linking; **single-mirror** (the contents of `home/` mirror straight into `$HOME/`, e.g. `home/.config/zsh/.zshrc` → `~/.config/zsh/.zshrc`); `--dry-run` / `--force`.
