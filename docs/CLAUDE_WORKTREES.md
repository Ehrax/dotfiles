# Claude Code Worktrees

Claude Code has built-in worktree support that creates isolated git worktrees for parallel development, each running in its own tmux session.

## Commands

| Command | Description |
|---------|-------------|
| `cw` | Launch Claude Code in a new worktree (auto-named) |
| `cw my-feature` | Launch Claude Code in a named worktree |
| `cwl` | List all git worktrees |
| `cwd <path>` | Remove a worktree by path (use `cwl` to find paths) |

## How It Works

`cw` is a fish function that runs:

```bash
claude --dangerously-skip-permissions --model opus --worktree --tmux
```

- `--worktree [name]` creates a new git worktree under `.claude/worktrees/`
- `--tmux` runs the session in a tmux pane (uses iTerm2 native panes when available)
- On session exit, Claude prompts to keep or remove the worktree

## Example Workflow

```bash
cd ~/Projects/my-app

# Start two parallel Claude sessions in worktrees
cw feature-auth     # named worktree
cw                  # auto-named worktree

# Check active worktrees
cwl

# Clean up when done
cwd .claude/worktrees/feature-auth
```

## Tips

- **Dependencies**: After creating a worktree, run your package manager (`npm install`, `pub get`, etc.) — dependencies are not shared between worktrees
- **Shared git state**: Stashes, tags, and remote tracking are shared across all worktrees
- **Branch lock**: You cannot check out the same branch in two worktrees simultaneously
- **Don't delete worktree directories manually** — always use `cwd` or `git worktree remove` so git cleans up its internal references
