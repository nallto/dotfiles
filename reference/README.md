# reference/

Version-controlled **snapshots** of app config that can't (or shouldn't) live as a
symlinked dotfile under `home/`. Nothing here is deployed by `dotman` — it exists for
**auditability** (git history of how settings changed) and **reproducibility** (re-apply
by hand or with a small script). Update it deliberately, so it doesn't churn like a live symlink.

Use it for config that the **app itself rewrites** (font-size, dock, theme, sync state) —
a symlink would churn and can be clobbered by atomic saves. The symlink-vs-reference rule: humans-only write → symlink; app also writes → reference.

Current snapshots:
- `vscode/` — VS Code (Settings Sync is the source of truth)
- `claude/` — Claude Code `settings.json` + `statusline-command.sh`
- `zed/`    — Zed `settings.json`

⚠️ Review each snapshot before committing — do not capture secrets/tokens.
