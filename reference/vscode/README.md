# reference/vscode/

VS Code is primarily managed by **Settings Sync**; these files are an audited snapshot
for reproducibility and review. Not deployed automatically.

## Files
- `settings.json`     — VS Code user settings (fonts, editor, formatter)
- `keybindings.json`  — user keybindings
- `extensions.txt`    — installed extension IDs (`code --list-extensions`)

## Snapshot (on the machine that has the desired config)
```sh
code --list-extensions > extensions.txt
cp "$HOME/Library/Application Support/Code/User/settings.json"    settings.json
cp "$HOME/Library/Application Support/Code/User/keybindings.json" keybindings.json
```

## Restore (new machine)
```sh
xargs -n1 code --install-extension < extensions.txt
cp settings.json    "$HOME/Library/Application Support/Code/User/settings.json"
cp keybindings.json "$HOME/Library/Application Support/Code/User/keybindings.json"
# Linux path: ~/.config/Code/User/
```

⚠️ `settings.json` can contain extension secrets/tokens — review before committing.
