# Static checks — the single source of truth for lint/format/test, run the same
# way locally (`make check`) and in CI (.github/workflows/ci.yml calls `make check`).
# Tools: shellcheck (mac=brew / Linux=apt), taplo (mac=brew / Linux=mise), zsh, bash, tmux.

SHELL_FILES := bootstrap.sh dotman.sh reference/claude/statusline-command.sh home/.local/bin/launchman
BASH_FILES  := bootstrap.sh dotman.sh home/.local/bin/launchman
TOML_FILES  := home/.config/starship.toml home/.config/mise/config.toml
ZSH_FILES   := home/.zshenv home/.config/zsh/.zshrc home/.config/zsh/.zprofile home/.config/zsh/aliases.zsh home/.config/zsh/guards.zsh
TMUX_FILES  := home/.config/tmux/tmux.conf

.PHONY: help check lint fmt fmt-check test dry-run

help: ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*##' '{printf "  %-11s %s\n", $$1, $$2}'

check: lint fmt-check test ## run all static checks (CI entry point)

lint: ## shellcheck the shell scripts
	shellcheck $(SHELL_FILES)

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
