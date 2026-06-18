# statusline-kit

A ready-to-use **two-line status line for [Claude Code](https://claude.com/claude-code)**.
Line 1 = live metrics (context / cost / tokens), line 2 = identity (model / git branch / project path). Every value gets its own color so it's readable at a glance.

![layout](https://img.shields.io/badge/lines-2-blue) ![deps](https://img.shields.io/badge/deps-jq%20%7C%20python3%20%7C%20ccusage-green)

## What it shows

**Line 1 — metrics**
- `Context ████░░ 42%` — context window usage (bar + %)
- `Cost $1.23 · $0.80/hr` — session cost + burn rate (rate needs `ccusage`)
- `+120 -30` — lines added / removed this session
- `Tok 0.10M/2.40M` — current-window tokens / session-cumulative tokens

**Line 2 — identity**
- `Opus 4.8` — current model (auto-shortened)
- `git:(main*)` — branch (`*` = dirty)
- `~/projects/xxx` — which folder this window is in

## Install

```bash
cp scripts/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then in `~/.claude/settings.json`:
```json
{ "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" } }
```

Reopen a Claude Code session.

**Dependencies:** `jq` (required), `python3` (session-cumulative tokens), `ccusage` (optional burn rate).

## Customize colors

Edit the `# Distinct accent palette` block at the top of `scripts/statusline.sh`. Colors are 256-color ANSI codes (`\033[38;5;<N>m`, N = 0–255).

## As a Claude Code skill

Drop the whole folder into `~/.claude/skills/statusline-kit/` and Claude Code can install / recolor / explain the status line on request. See `SKILL.md`.

## License

MIT
