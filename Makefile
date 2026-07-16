# Static checks — the single source of truth for lint/format/test, run the same
# way locally (`make check`) and in CI (.github/workflows/ci.yml calls `make check`).
# Tools: shellcheck (mac=brew / Linux=apt), taplo (mac=brew / Linux=mise), zsh, bash.

SHELL_FILES := bootstrap.sh dotman.sh reference/claude/statusline-command.sh
BASH_FILES  := bootstrap.sh dotman.sh
TOML_FILES  := home/.config/starship.toml home/.config/mise/config.toml
ZSH_FILES   := home/.zshenv home/.config/zsh/.zshrc home/.config/zsh/.zprofile home/.config/zsh/aliases.zsh

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

test: ## syntax-check shell (bash -n) and zsh (zsh -n)
	@for f in $(BASH_FILES); do echo "bash -n $$f"; bash -n "$$f" || exit 1; done
	@for f in $(ZSH_FILES);  do echo "zsh -n  $$f"; zsh  -n "$$f" || exit 1; done

dry-run: ## preview dotman placement (no changes)
	./dotman.sh -i --dry-run
