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
| `configs/codex/config.toml` | `~/.codex/config.toml` |
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
