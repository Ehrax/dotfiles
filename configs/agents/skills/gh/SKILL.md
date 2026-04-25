---
name: gh
description: Use when interacting with GitHub from the command line — creating and managing pull requests, issues, releases, workflows, repositories, and any other GitHub operation. Covers all gh CLI commands including pr, issue, repo, release, run, workflow, search, and api. Enforces conventional commits for PR titles and structured descriptions.
---

# GitHub CLI (gh)

Manage GitHub entirely from the terminal using `gh`. This skill covers creating pull requests, triaging issues, running Actions workflows, cutting releases, and making raw API calls — all without leaving your shell.

## When to Use

- Creating, reviewing, merging, or listing pull requests
- Creating, listing, updating, or closing issues
- Triggering, monitoring, or canceling GitHub Actions runs
- Creating releases with notes and assets
- Cloning, forking, or managing repositories
- Searching across GitHub (repos, code, issues, PRs)
- Making raw REST or GraphQL API calls

## Prerequisites

- `gh` installed (`brew install gh`)
- Authenticated via `gh auth login`
- Inside a Git repository with a GitHub remote (or use `-R OWNER/REPO`)

## Command Structure

```
gh <command> <subcommand> [flags]
```

All commands support `--help` and `-R`/`--repo [HOST/]OWNER/REPO`.

## Reference Guides

| Topic | File | Load when... |
|-------|------|-------------|
| Writing PRs & issues | `references/writing-prs-and-issues.md` | Writing titles, descriptions, conventional commits, PR body structure |
| Pull requests | `references/pull-requests.md` | Creating, reviewing, merging, listing PRs |
| Issues | `references/issues.md` | Creating, listing, updating, closing issues |
| Actions & releases | `references/actions-and-releases.md` | Workflows, runs, releases, assets |

## Core Workflows

### Create a Pull Request

Always use conventional commits in PR titles. See `references/writing-prs-and-issues.md` for full guidelines.

```bash
# Non-interactive — conventional title, body via heredoc
gh pr create \
  --title "feat(auth): add OAuth2 login" \
  --body "$(cat <<'EOF'
## Description
Adds Google and GitHub OAuth2 login via Passport.js.

Closes #123

## How to test
1. `npm install && npm run dev`
2. Navigate to `/login`
3. Click "Sign in with Google" — should redirect and authenticate
4. Verify session persists on refresh

## Checklist
- [x] Tests added
- [x] Docs updated
EOF
)"

# Fill title/body from commit messages, then open editor to refine
gh pr create --fill

# Draft PR for early feedback
gh pr create --title "feat(api): v2 migration" --draft
```

### Create an Issue

Before creating an issue in a repo you have not worked in recently, inspect the latest issue titles and mirror the dominant pattern. Do not assume conventional commits or bare imperative titles are acceptable for issues.

```bash
# Inspect recent issue titles first
gh issue list --state all --limit 20 --json number,title

# Bug report
gh issue create \
  --title "[Bug]: Login button unresponsive on iOS Safari 17" \
  --label "bug,P1" \
  --body "$(cat <<'EOF'
## Summary
The login button does nothing on iOS Safari 17 — no network request fires.

## Steps to reproduce
1. Open `/login` on iOS Safari 17
2. Fill in email and password
3. Tap "Sign in"
4. Observe: nothing happens

**Expected**: Form submits and redirects to dashboard.
**Actual**: Button tap has no effect.

## Environment
- Device: iPhone 15 Pro
- OS: iOS 17.4
- App version: v2.3.1
EOF
)"

# Feature request
gh issue create \
  --title "[Feature]: Add dark mode toggle" \
  --label "enhancement" \
  --body "As a user I want dark mode so my eyes don't hurt at night."
```

### Review and Merge a PR

```bash
gh pr list                        # PRs in current repo
gh pr diff 42                     # View diff
gh pr review 42 --approve         # Approve
gh pr merge 42 --squash           # Merge (squash)
gh pr checks 42                   # CI status
```

### Actions & Releases

```bash
gh run list                       # Recent workflow runs
gh run watch                      # Live-watch current run
gh workflow run deploy.yml        # Trigger workflow manually

gh release create v1.2.0 ./dist/*.tar.gz \
  --generate-notes \
  --title "v1.2.0 — Auth improvements"
```

### Raw API Calls

```bash
# REST
gh api repos/:owner/:repo/pulls

# GraphQL
gh api graphql -f query='{ viewer { login } }'

# With pagination
gh api issues --paginate
```

## All Top-Level Commands

| Command | Purpose |
|---------|---------|
| `gh api` | Raw REST/GraphQL API calls |
| `gh auth` | Authenticate to GitHub |
| `gh browse` | Open repo/PR/issue in browser |
| `gh codespace` | Manage Codespaces |
| `gh gist` | Manage gists |
| `gh issue` | Manage issues |
| `gh label` | Manage labels |
| `gh org` | Organization operations |
| `gh pr` | Manage pull requests |
| `gh project` | GitHub Projects |
| `gh release` | Manage releases |
| `gh repo` | Manage repositories |
| `gh run` | GitHub Actions runs |
| `gh search` | Search GitHub |
| `gh secret` | Manage secrets |
| `gh variable` | Manage Actions variables |
| `gh workflow` | Manage Actions workflows |

## Tips

- **Title conventions**: Always use conventional commits for PR titles (`feat(scope): title`). See `references/writing-prs-and-issues.md`.
- **Issue title conventions**: Inspect recent issue titles before creating a new one and mirror the repo's existing pattern. If the repo uses bracketed prefixes such as `[Feature]: ...` or `[Infra]: ...`, keep using them for every new issue.
- **Auto-detection**: `gh` reads your Git remote to determine the repo — no need for `-R` inside the project.
- **Body via heredoc**: Use `--body "$(cat <<'EOF' ... EOF)"` to pass multi-line bodies without an editor.
- **Closing issues**: Include `Closes #123` in the PR body — GitHub auto-closes the issue on merge.
- **Web fallback**: Add `--web` to any create command to open the browser form instead.
