# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal macOS dotfiles for Alexander Rasputin. One-script setup (`./init.sh`) that installs Homebrew packages, creates symlinks from `configs/` to `~/.config/`, sets up Fish shell, and optionally configures Flutter/Ruby/Node.js environments.

## Architecture

### Symlink Model

Everything in `configs/` gets symlinked to its target location. Editing files here immediately affects the live environment. Key mappings:

| Source | Target |
|--------|--------|
| `configs/fish/config.fish` | `~/.config/fish/config.fish` |
| `configs/fish/fish_plugins` | `~/.config/fish/fish_plugins` |
| `configs/nvim/` | `~/.config/nvim/` |
| `configs/ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `configs/git/config` | `~/.gitconfig` |
| `configs/git/ignore` | `~/.gitignore` |
| `configs/tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `configs/starship/starship.toml` | `~/.config/starship.toml` |
| `configs/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `configs/claude/settings.json` | `~/.claude/settings.json` AND `~/.claude-work/settings.json` |
| `configs/claude/mcp.json` | `~/.claude/mcp.json` AND `~/.claude-work/mcp.json` |
| `configs/claude/statusline.sh` | `~/.claude/statusline.sh` |
| `configs/agents/skills/` | `~/.claude/skills/`, `~/.claude-work/skills/`, `~/.config/opencode/skills/`, `~/.gemini/skills/`, AND `~/.codex/skills/` |
| `configs/opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `configs/tmux/gitmux.conf` | `~/.config/tmux/gitmux.conf` |

### Dual Claude Config

Two Claude Code profiles exist, switchable via `cc` (personal → `~/.claude`) and `cw` (work → `~/.claude-work`). Both share the same `settings.json`, `mcp.json`, skills, and plugins from this repo, and OpenCode shares the same skills source. The active profile is persisted via `CLAUDE_CONFIG_DIR` in `~/.fish_claude_dir` and restored on shell startup.

### Neovim

LazyVim distribution with custom overrides in `configs/nvim/lua/`. Key deviations from LazyVim defaults: 4-space tabs, no relative line numbers, conceallevel 0, all animations and indent guides disabled, inlay hints off, render-markdown disabled. Ctrl+h/j/k/l navigates seamlessly between vim splits and tmux panes.

### One Dark Theme

Consistent One Dark colorscheme (`bg: #21252b`) across Ghostty, Neovim, tmux, lazygit, and the Claude statusline. When adding or modifying terminal/UI config, keep this palette.

## Commands

```bash
./init.sh                        # Full interactive setup (prompts for each step — cannot run unattended)
brew bundle --file=Brewfile      # Install/update Homebrew packages
bash scripts/macos.sh            # Apply macOS system preferences (keyboard repeat, Finder, Dock)
bash scripts/sweep.sh [--dry-run] # Interactive disk cleanup (requires gum)
```

## Shell Aliases (Fish)

Key aliases defined in `configs/fish/config.fish`:
- `c` — launch Claude Code (permission-mode auto)
- `cc` / `cw` — switch Claude config to personal / work
- `lg` — lazygit
- `v` / `vim` — nvim
- `sweep` — interactive disk cleanup (requires gum)
- `reload` — re-source fish config

## Conventions

- **Shell scripts**: Use `bash` with `set -e`. Use the helper functions from `init.sh` (`print_step`, `print_success`, etc.) for consistent output formatting.
- **Symlinks**: Always add new config symlinks inside `init.sh`'s symlink section. Never manually copy configs to target locations.
- **Brewfile**: Add new packages to `Brewfile` in the appropriate section. Keep the section comments and categorization.
- **Git**: Pull with rebase (`pull.rebase = true`), auto-setup remote on push, delta for diffs. Default branch for new repos is `main`.
- **Tmux prefix**: `Ctrl+Space` (not the default `Ctrl+b`).
- **Archive**: `archive/` contains deprecated configs (old zsh theme, nvmrc). Not symlinked or active.

## Gotchas

- `init.sh` is interactive (`ask_yes_no` prompts) — it cannot be run non-interactively or piped.
- `create_symlink` in `init.sh` backs up existing non-symlink targets to `<path>.backup` before overwriting. If a backup already exists, it skips to avoid data loss.
- Ghostty uses `term = xterm-256color` (not `xterm-ghostty`) for compatibility with CLI tools like Claude Code that don't recognize the Ghostty terminfo.
- Configs are live-symlinked — any edit in this repo takes effect immediately in the running environment. There is no "deploy" step.
- Fish shell aliases shadow system commands (`cat` → `bat`, `ls` → `eza`, `grep` → `rg`, `find` → `fd`). Use the original binary path (e.g., `/usr/bin/grep`) if you need unaliased behavior.
