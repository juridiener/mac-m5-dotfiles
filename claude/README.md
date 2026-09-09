# New machine setup

This directory is git-tracked and holds the whole Claude Code config (settings,
hooks, skills, plugins). Cloning it is not enough by itself — Claude Code never
reads `~/.config/claude` directly, only `~/.claude`. One manual step bridges that.

## Required — do this first, before starting any Claude Code session

```bash
ln -s ~/.config/claude ~/.claude
```

Without this symlink, Claude Code falls back to defaults and silently ignores
everything in this repo — no error, it just won't load.

## Verify it worked

```bash
readlink ~/.claude          # should print: /Users/<you>/.config/claude
cat ~/.claude/settings.json | head -1   # should print valid JSON, not "no such file"
```

## Known non-portable bit

`settings.json` → `permissions.allow` has one entry hardcoded to the current
username:

```
"Read(//Users/DienerJuri/.config/**)"
```

This is a permission glob, not a hook command — unlike hook `command` strings,
it's unverified whether `$HOME` expands inside permission patterns. If the new
machine has a different macOS username, this line just won't match and Claude
Code will prompt for permission the first time it reads under `.config/` on
that machine instead of auto-allowing it. Not a hard failure — reapprove when
prompted, or manually update the path once logged in on the new machine.

Every hook `command` entry in `settings.json` (caveman hooks, context-mode
heal, the feature-docs-gate Stop hook, the statusline command) uses `$HOME`
instead of a hardcoded path, so those are already portable across usernames.
