# Pull Requests — gh CLI Reference

## Create

```bash
gh pr create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <string>` | PR title (use conventional commits format) |
| `-b, --body <string>` | PR body |
| `-F, --body-file <file>` | Read body from file (`-` for stdin) |
| `-B, --base <branch>` | Target branch (default: repo default branch) |
| `-H, --head <branch>` | Source branch (default: current) |
| `-d, --draft` | Open as draft |
| `-f, --fill` | Fill title/body from commit messages |
| `--fill-verbose` | Use all commit messages for body |
| `-r, --reviewer <handle>` | Request reviews |
| `-a, --assignee <login>` | Assign (use `@me` to self-assign) |
| `-l, --label <name>` | Add labels |
| `-m, --milestone <name>` | Add to milestone |
| `-p, --project <title>` | Add to project |
| `-w, --web` | Open browser form instead |
| `--dry-run` | Print what would be created |

## List & View

```bash
gh pr list                          # Open PRs in current repo
gh pr list --state all              # All states
gh pr list --author "@me"           # Your PRs
gh pr list --reviewer "@me"         # PRs awaiting your review
gh pr list --label "bug"            # Filter by label
gh pr list --base main              # PRs targeting main

gh pr view 42                       # View PR details
gh pr view 42 --web                 # Open in browser
gh pr diff 42                       # View diff in terminal
gh pr checks 42                     # CI check statuses
```

## Review

```bash
gh pr review 42 --approve                          # Approve
gh pr review 42 --request-changes --body "..."     # Request changes
gh pr review 42 --comment --body "Looks good but..."
```

## Merge

```bash
gh pr merge 42                      # Interactive merge (prompts for method)
gh pr merge 42 --merge              # Merge commit
gh pr merge 42 --squash             # Squash and merge
gh pr merge 42 --rebase             # Rebase and merge
gh pr merge 42 --auto               # Enable auto-merge (merges when CI passes)
gh pr merge 42 --delete-branch      # Delete branch after merge
```

## Edit & Update

```bash
gh pr edit 42 --title "fix(auth): correct token expiry"
gh pr edit 42 --body "Updated description"
gh pr edit 42 --add-label "ready" --remove-label "WIP"
gh pr edit 42 --add-reviewer teamlead

gh pr ready 42                      # Mark draft as ready for review
gh pr close 42                      # Close without merging
gh pr reopen 42                     # Reopen closed PR
```

## Checkout

```bash
gh pr checkout 42                   # Check out PR branch locally
```

## Comments

```bash
gh pr comment 42 --body "LGTM!"
gh pr comment 42 --edit-last        # Edit your last comment
```
