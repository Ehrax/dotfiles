# Dotfiles

Personal macOS development environment — one script to rule them all.

<!-- TODO: Add terminal screenshot -->
<!-- ![Setup](assets/screenshot.png) -->

## Quick Start

```bash
git clone https://github.com/Ehrax/dotfiles ~/Projects/Dotfiles
cd ~/Projects/Dotfiles
./init.sh
```

The interactive setup handles Homebrew packages, symlinks, Fish shell, and optional dev environments (Flutter, Ruby, Node.js).

## What's Included

### Shell & Terminal

- **Fish** — Modern shell with great defaults
- **Starship** — Minimal, fast prompt
- **Ghostty** — GPU-accelerated terminal (One Dark theme)
- **tmux** — Terminal multiplexer with session persistence

### Editor

- **Neovim** + LazyVim — LSP, treesitter, One Dark theme

### CLI Tools

| Tool | Replaces | Purpose |
|------|----------|---------|
| `bat` | cat | Syntax highlighting |
| `eza` | ls | Icons, git integration |
| `fd` | find | Faster, simpler syntax |
| `ripgrep` | grep | Blazing fast search |
| `zoxide` | cd | Smart directory jumping |
| `delta` | diff | Beautiful git diffs |
| `btop` | top | Resource monitor |
| `lazygit` | — | Terminal UI for git |

### Dev Environments

fnm (Node.js) · bun · rbenv (Ruby) · fvm (Flutter) · Claude Code

## Structure

```
configs/       Shell, editor, terminal, git configs (symlinked to ~/.config/)
scripts/       macOS system preferences
docs/          Setup guides and references
Brewfile       Homebrew packages
init.sh        Setup script
```

## Post-Install

1. Restart terminal or run `exec fish`
2. Open Neovim — plugins auto-install
3. Logout/restart for keyboard repeat settings

## Docs

- [Keybindings](docs/KEYBINDINGS.md)
- [Tmux Setup](docs/TMUX_SETUP.md)
- [Flutter Setup](docs/FLUTTER_SETUP.md)
- [macOS Setup](docs/MACOS_SETUP.md)
- [Claude Worktrees](docs/CLAUDE_WORKTREES.md)

## Customization

Configs are symlinked — edit files in this repo and changes apply immediately. Add Homebrew packages to `Brewfile` and run `brew bundle`.
