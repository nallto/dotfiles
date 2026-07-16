# reference/zed/

Audited **snapshot** of Zed's user config. NOT symlinked: Zed writes to
`~/.config/zed/settings.json` itself (font-size cmd±, dock positions, theme
picker, panel state), so an atomic save could clobber a symlink and would mix
ephemeral UI state into version control. We keep a copy here and refresh it
deliberately.

## Files
- `settings.json` — Zed user settings (`~/.config/zed/settings.json`)

## Snapshot (after intentionally changing Zed settings)
```sh
cp ~/.config/zed/settings.json reference/zed/settings.json
```

## Restore (new machine)
```sh
mkdir -p ~/.config/zed
cp reference/zed/settings.json ~/.config/zed/settings.json
```
