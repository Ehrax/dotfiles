---
name: gh-pr
description: Commit all changes and create a GitHub pull request with a high-quality summary and testing instructions. Optionally closes an issue passed as URL or reference.
argument-hint: [issue-url-or-ref]
disable-model-invocation: true
allowed-tools: Skill(gh), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh:*)
---

# Commit And Create GitHub PR

Use the `gh` skill conventions and create a complete PR flow from current branch changes.

## Arguments

- `$ARGUMENTS` is optional.
- If provided, treat it as an issue reference and support:
  - GitHub issue URL (`https://github.com/<owner>/<repo>/issues/12`)
  - short reference (`#12`)
  - bare number (`12`)

## Required Workflow

1. Load and follow the `gh` skill guidance first.
2. Inspect current repo state with:
   - `git status`
   - `git diff HEAD`
   - `git branch --show-current`
   - `git log --oneline -10`
3. Commit all current changes as exactly one conventional commit:
   - If there are no local changes, skip commit and continue.
   - Otherwise run `git add -A` and `git commit -m "<conventional-message>"`.
4. Ensure the current branch is pushed:
   - If branch has no upstream, push with `git push -u origin <branch>`.
   - Otherwise push with `git push`.
5. Build a PR title using conventional commit style.
6. Build a PR body using this structure:

```markdown
## Summary
- <1-3 bullets describing why this change exists and what it improves>

## Testing
1. <exact command to run>
2. <exact command to run>
3. <expected outcome>

## Notes
- <risk/rollback/migration note, or "None">
```

7. If an issue argument was provided and a number can be extracted, append:
   - `Closes #<number>`
   - If parsing fails, include the raw argument in Notes.
8. Create PR non-interactively with `gh pr create --title ... --body ...`.

## Output

Return:

- created commit hash/message (or note that no commit was needed)
- PR URL
- final issue-closing line used (if any)
