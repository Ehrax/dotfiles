# AGENTS.md

Personal macOS dotfiles for Alexander Rasputin: `./init.sh` installs Homebrew packages and symlinks `configs/` to live target locations, no deploy step.

| Source | Target |
|--------|--------|
| `configs/fish/config.fish` | `~/.config/fish/config.fish` |
| `configs/fish/fish_plugins` | `~/.config/fish/fish_plugins` |
| `configs/nvim/` | `~/.config/nvim/` |
| `configs/starship/starship.toml` | `~/.config/starship.toml` |
| `configs/ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `configs/cmux/cmux.json` | `~/.config/cmux/cmux.json` |
| `configs/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `configs/git/config` | `~/.gitconfig` |
| `configs/git/ignore` | `~/.gitignore` |
| `configs/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `configs/tmux/gitmux.conf` | `~/.config/tmux/gitmux.conf` |
| `configs/claude/settings.json` | `~/.claude/settings.json` AND `~/.claude-work/settings.json` |
| `configs/claude/mcp.json` | `~/.claude/mcp.json` AND `~/.claude-work/mcp.json` |
| `configs/claude/statusline.sh` | `~/.claude/statusline.sh` |
| `configs/agents/skills/` | `~/.agents/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, `~/.gemini/skills`, `~/.codex/skills` |
| `configs/opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `~/.claude/plugins` | `~/.claude-work/plugins` (symlinked to each other) |
| `~/.claude/skills` | `~/.claude-work/skills` (symlinked to each other) |

`cc`/`cw` fish functions switch Claude config dir personal/work (both share this repo's settings/mcp/skills/plugins). Aliases: `c` (claude --dangerously-skip-permissions), `cx` (codex --yolo), `wt`/`wtl`/`wtr`/`wtc` (worktree create/list/remove/cd).

## Commands

```bash
./init.sh                         # interactive only — cannot run unattended or piped
bash scripts/macos.sh             # apply macOS system prefs
bash scripts/sweep.sh [--dry-run] # interactive disk cleanup (requires gum)
```

## Footguns

- `create_symlink` in `init.sh` backs up an existing non-symlink target to `<path>.backup`; if a backup already exists it skips the file rather than clobbering it.
- Ghostty pins `term = xterm-256color` (not `xterm-ghostty`) — some CLI tools (e.g. Codex) mishandle the Ghostty terminfo.
- Fish aliases shadow system commands (`cat`→`bat`, `ls`→`eza`, `grep`→`rg`, `find`→`fd`, `top`→`btop`); use `command <name>` for the real binary.
- Tmux prefix is `Ctrl+Space`, not `Ctrl+b`.

## Picking models for delegated work

Rankings, higher = better. Cost reflects real subscription pressure, not list price.
Intelligence = how hard a problem the model handles unsupervised. Taste = UI/UX, code
quality, API design, copy.

| model     | cost | intelligence | taste |
|-----------|------|--------------|-------|
| gpt-5.5   | 7    | 8            | 5     |
| opus-4.8  | 4    | 7            | 8     |
| sonnet-5  | 6    | 5            | 7     |

- Don't start dev servers (assume one is already running) and don't run builds unless told — verify with the project's check commands (typecheck, lint, tests).
- If asked to do too much work at once, stop and state that clearly.
- If computer use helps to complete or verify work (clicking through a UI, screenshots), shell out to gpt-5.5 with codex — it has built-in computer use.
- Defaults, not limits: if a cheaper model's output misses the bar, redo with a smarter one without asking. Judge the output, not the price tag.
- When axes conflict for anything that ships: intelligence > taste > cost.
- Bulk/mechanical with a tight brief (clear-spec implementation, migrations, commit/push sweeps): gpt-5.5. Never pick haiku on your own — the user invokes it explicitly when wanted.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7: opus-4.8, sonnet-5 as budget option.
- Default driver split: gpt-5.5 drives backend and logic work (services, data, glue — including logic inside frontend code); Claude drives frontend/visual work.
- Reviews of plans/implementations: opus-4.8, plus gpt-5.5 as an independent second perspective.
- Also on the codex account (via `codex -m`): gpt-5.4, gpt-5.4-mini, gpt-5.3-codex-spark (very fast execution) — the user invokes these explicitly; don't auto-pick them.
- Mechanics: gpt-5.5 only via the codex CLI (`codex exec` / `codex review`); Claude models via the Agent/Workflow `model` parameter. Full delegation playbook: the `orchestrate` skill.
