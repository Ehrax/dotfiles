# Git Worktrees for Parallel Development

Git worktrees let you check out multiple branches simultaneously in separate directories, sharing a single `.git` history. This is ideal for running multiple Claude Code instances in parallel — each gets its own clean working directory.

## How It Works

Worktrees are created as **sibling directories** next to your project:

```
~/Projects/
  my-app/                  # main branch (original checkout)
  my-app-feature-auth/     # feature-auth branch (worktree)
  my-app-fix-header/       # fix-header branch (worktree)
```

Each directory is a full working copy with its own branch, but they all share the same git history and remote.

## Functions Reference

| Function | Usage                      | Description                                       |
| -------- | -------------------------- | ------------------------------------------------- |
| `wt`     | `wt feature-name [base]`  | Create worktree + branch as sibling dir (default base: `main`) |
| `wtl`    | `wtl`                      | List all worktrees                                |
| `wtc`    | `wtc feature-name`         | CD into a worktree                                |
| `wtr`    | `wtr feature-name`         | Remove a worktree and prune                       |
| `wtcc`   | `wtcc feature-name [base]` | Create worktree + launch Claude Code              |

## Example Workflow

```bash
cd ~/Projects/my-app

# Create two worktrees for parallel Claude Code tasks
wt feature-auth
wt fix-header

# List them
wtl

# Open Claude Code in each (in separate terminal tabs)
wtc feature-auth
c                          # or use wtcc to create + launch in one step

# In another tab
wtc fix-header
c

# When done, merge branches via PR, then clean up
wtr feature-auth
wtr fix-header
```

## Tips

- **Base branch**: Pass a second argument to `wt` to branch from something other than `main`: `wt my-fix develop`
- **Slash branches**: Branch names with `/` (like `feature/auth`) are handled automatically — the directory becomes `project-feature-auth`
- **Dependencies**: After creating a worktree, run your package manager (`npm install`, `pub get`, etc.) — dependencies are not shared between worktrees
- **Works from anywhere**: All `wt*` functions work from any worktree or subdirectory within the project
- **Shared git state**: Stashes, tags, and remote tracking are shared across all worktrees
- **Branch lock**: You cannot check out the same branch in two worktrees simultaneously — git prevents this

## Pitfalls

- **Don't delete worktree directories manually** — always use `wtr` (or `git worktree remove`) so git cleans up its internal references
- **Node modules / build caches**: Each worktree has its own `node_modules`, `.dart_tool`, etc. This uses extra disk space but ensures isolation
- **IDE state**: If using an IDE, open each worktree as a separate project/window
