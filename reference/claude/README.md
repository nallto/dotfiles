# reference/claude/

Audited **snapshots** of Claude Code user config. NOT symlinked: Claude Code writes to
`~/.claude/settings.json` itself (`/config`, agents, version pinning), and tools that
atomic-save can clobber a symlink — so we keep a copy here and refresh it deliberately.

## Files
- `settings.json`         — Claude Code user settings (theme, effortLevel, statusLine)
- `statusline-command.sh` — powerline status line script referenced by settings.json
- `themes/`               — custom Claude Code themes (e.g. night-chill.json, `theme: "custom:<name>"`)

## Snapshot (after changing Claude Code settings)
```sh
cp ~/.claude/settings.json          reference/claude/settings.json
cp ~/.claude/statusline-command.sh  reference/claude/statusline-command.sh
cp -R ~/.claude/themes/.            reference/claude/themes/
```

## Restore (new machine)
```sh
cp reference/claude/settings.json          ~/.claude/settings.json
cp reference/claude/statusline-command.sh  ~/.claude/statusline-command.sh
cp -R reference/claude/themes/.            ~/.claude/themes/
```
Note: statusLine.command uses `~/.claude/statusline-command.sh` — Claude Code runs the
command through a shell, so `~` expands to the current user's home on any machine.

## Never snapshot (secrets / state — stay local, unmanaged)
~/.claude.json (tokens, MCP config, project history), ~/.claude/projects/,
sessions/, history.jsonl, statsig/, shell-snapshots/.
