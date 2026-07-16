# Brewfile — macOS package manifest. Applied via `brew bundle` (.zprofile points
# HOMEBREW_BUNDLE_FILE here; bootstrap.sh passes --file explicitly).
# mac-only: Linux uses apt + mise instead (see linux/apt-packages.txt).

# --- base / single-use utilities (mac = brew; Linux = apt) ---
brew "btop"        # resource / process monitor
brew "cloc"        # count lines of code
brew "curl"        # transfer files over HTTP/HTTPS/FTP
brew "gh"          # GitHub CLI
brew "ghq"         # clone and organize repos under a tidy tree
brew "git"         # version control
brew "git-lfs"     # git extension for large files (run `git lfs install` once)
brew "jq"          # command-line JSON processor
brew "lazygit"     # terminal UI for git
brew "sd"          # intuitive find & replace (sed alternative)
brew "shellcheck"  # shell script static analysis (make lint / CI)
brew "taplo"       # TOML formatter / linter (starship.toml, mise config, ...)
brew "tealdeer"    # `tldr` client — quick command examples (run `tldr --update`)
brew "tig"         # text-mode interface for git
brew "vim"         # editor
brew "watch"       # run a command periodically, fullscreen
brew "wget"        # download files over HTTP/HTTPS/FTP
brew "xdg-ninja"   # check $HOME for files that should follow XDG
brew "zsh"         # shell

# --- runtime & language tooling ---
brew "mise"        # polyglot runtime version manager
brew "uv"          # fast Python package / venv manager

# --- shared-config reference CLIs (mac = brew; Linux = mise) ---
brew "bat"         # cat with syntax highlighting
brew "eza"         # modern ls replacement
brew "fd"          # fast, friendly find replacement
brew "fzf"         # fuzzy finder
brew "git-delta"   # syntax-highlighting pager for git diffs
brew "ripgrep"     # fast recursive grep (rg)
brew "starship"    # cross-shell prompt
brew "zoxide"      # smarter cd (frecency jumps)

# --- zsh plugins (kept in .zshrc load order; sourced directly, no plugin manager) ---
brew "zsh-autosuggestions"           # fish-like autosuggestions
brew "zsh-syntax-highlighting"       # fish-like command syntax highlighting
brew "zsh-history-substring-search"  # up/down substring history search

# --- GNU coreutils parity (macOS only; for script parity) ---
brew "coreutils"   # GNU file/shell/text utilities
brew "diffutils"   # GNU diff / cmp
brew "findutils"   # GNU find / xargs / locate
brew "gawk"        # GNU awk
brew "gnu-sed"     # GNU sed
brew "gnu-tar"     # GNU tar
brew "gnu-which"   # GNU which
brew "grep"        # GNU grep
brew "gzip"        # GNU gzip

# --- GUI apps (Cask) ---
cask "claude-code"          # terminal-based AI coding assistant
cask "discord"              # voice & text chat
cask "ghostty"              # GPU-accelerated terminal emulator
cask "google-chrome"        # web browser
cask "obsidian"             # Markdown knowledge base
cask "readdle-spark"        # email client
cask "slack"                # team chat
cask "visual-studio-code"   # code editor
cask "zed"                  # code editor

# --- Fonts (Cask) ---
cask "font-moralerspace-hw-jpdoc"  # Moralerspace HW JPDOC — JP coding font (Monaspace + IBM Plex Sans JP)
cask "font-udev-gothic"      # UDEV Gothic — JP coding font (JetBrains Mono + BIZ UDGothic)
cask "font-udev-gothic-hs"   # UDEV Gothic HS variant
cask "font-udev-gothic-nf"   # UDEV Gothic + Nerd Font glyphs
