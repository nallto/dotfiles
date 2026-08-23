# Static checks — the single source of truth for lint/format/test, run the same
# way locally (`make check`) and in CI (.github/workflows/ci.yml calls `make check`).
# Tools: shellcheck (mac=brew / Linux=mise / CI=pinned binary), taplo (mac=brew / Linux=mise),
# zsh, bash, tmux.
#
# shellcheck's version decides which warnings fire — 0.9 rejects `A && B || C` as SC2015 where
# 0.11 stays quiet — so a local run and CI only agree if they run the same one. This file holds
# the single declaration; .github/workflows/ci.yml and bootstrap.sh read it back with
# `make -s shellcheck-version`. Homebrew cannot pin a formula, so macOS drifts on its own
# schedule: `lint` warns about a mismatch instead of failing, and the fix is to bump the number
# below and re-run bootstrap on Linux.
SHELLCHECK_VERSION := 0.11.0

SHELL_FILES := bootstrap.sh dotman.sh reference/claude/statusline-command.sh home/.local/bin/launchman
BASH_FILES  := bootstrap.sh dotman.sh home/.local/bin/launchman
TOML_FILES  := home/.config/starship.toml home/.config/mise/config.toml
ZSH_FILES   := home/.zshenv home/.config/zsh/.zshrc home/.config/zsh/.zprofile home/.config/zsh/aliases.zsh home/.config/zsh/guards.zsh
TMUX_FILES  := home/.config/tmux/tmux.conf

.PHONY: help check lint fmt fmt-check test dry-run shellcheck-version

help: ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*##' '{printf "  %-18s %s\n", $$1, $$2}'

check: lint fmt-check test ## run all static checks (CI entry point)

lint: ## shellcheck the shell scripts
	@# An unparsable --version leaves $$have empty, which skips the warning rather than crying
	@# wolf; the lint below still runs, and a missing shellcheck still fails the target outright.
	@have=$$(shellcheck --version 2>/dev/null | sed -n 's/^version: //p' || true); \
	  [ "$$have" = "$(SHELLCHECK_VERSION)" ] || [ -z "$$have" ] || \
	  printf 'warning: shellcheck %s, pinned %s -- CI may disagree. Bump SHELLCHECK_VERSION in the Makefile.\n' \
	    "$$have" "$(SHELLCHECK_VERSION)" >&2
	shellcheck $(SHELL_FILES)

shellcheck-version: ## print the pinned shellcheck version (read by CI and bootstrap.sh)
	@printf '%s\n' "$(SHELLCHECK_VERSION)"

fmt: ## format TOML in place
	taplo fmt $(TOML_FILES)

fmt-check: ## verify TOML formatting + lint
	taplo fmt --check $(TOML_FILES)
	taplo lint $(TOML_FILES)

test: ## syntax-check shell (bash -n), zsh (zsh -n) and the tmux config
	@for f in $(BASH_FILES); do echo "bash -n $$f"; bash -n "$$f" || exit 1; done
	@for f in $(ZSH_FILES);  do echo "zsh -n  $$f"; zsh  -n "$$f" || exit 1; done
	@# tmux exits 0 even on a broken config, so treat any output as failure:
	@# source-file prints "file:LINE: message" for parse errors, nothing when clean.
	@for f in $(TMUX_FILES); do echo "tmux -f $$f"; \
	  msg=$$(tmux -f /dev/null -L dotfiles-check start-server \; source-file "$$f" \; kill-server 2>&1); \
	  [ -z "$$msg" ] || { echo "$$msg"; exit 1; }; done

dry-run: ## preview dotman placement (no changes)
	./dotman.sh -i --dry-run
