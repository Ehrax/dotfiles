# Issues — gh CLI Reference

## Create

```bash
gh issue create [flags]
```

| Flag | Description |
|------|-------------|
| `-t, --title <string>` | Issue title |
| `-b, --body <string>` | Issue body |
| `-F, --body-file <file>` | Read body from file (`-` for stdin) |
| `-a, --assignee <login>` | Assign (`@me` to self-assign) |
| `-l, --label <name>` | Add labels |
| `-m, --milestone <name>` | Add to milestone |
| `-p, --project <title>` | Add to project |
| `-T, --template <name>` | Use an issue template |
| `-w, --web` | Open browser form instead |

## List & View

```bash
gh issue list                          # Open issues
gh issue list --state all              # All states
gh issue list --state closed           # Closed issues
gh issue list --assignee "@me"         # Assigned to you
gh issue list --author "@me"           # Created by you
gh issue list --label "bug"            # Filter by label
gh issue list --milestone "v2.0"       # Filter by milestone
gh issue list --search "login"         # Full-text search

gh issue view 42                       # View issue details
gh issue view 42 --web                 # Open in browser
```

## Edit & Update

```bash
gh issue edit 42 --title "[Bug]: Updated title"
gh issue edit 42 --body "Updated description"
gh issue edit 42 --add-label "P1" --remove-label "triage"
gh issue edit 42 --add-assignee "@me"
gh issue edit 42 --milestone "v2.0"
```

## Close & Reopen

```bash
gh issue close 42
gh issue close 42 --comment "Fixed in #99"
gh issue reopen 42
```

## Comments

```bash
gh issue comment 42 --body "Can reproduce on v2.1"
gh issue comment 42 --edit-last
```

## Transfer & Pin

```bash
gh issue transfer 42 owner/other-repo
gh issue pin 42
gh issue unpin 42
```

## Common Workflows

```bash
# Create and self-assign a bug
gh issue create \
  --title "[Bug]: Checkout fails with empty cart" \
  --label "bug" \
  --assignee "@me"

# Search for duplicates before creating
gh issue list --search "login timeout" --state all

# Close with a reference to the fixing PR
gh issue close 42 --comment "Fixed by #99."
```
