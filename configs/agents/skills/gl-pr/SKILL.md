---
name: gl-pr
description: Commit all changes and create a GitLab merge request with a clear summary and testing instructions. Optionally closes an issue passed as URL or reference.
argument-hint: issue-url-or-ref
---

# Commit And Create GitLab MR

Use the `glab` skill conventions and create a full merge request flow from current branch changes.

## Arguments

- `$ARGUMENTS` is optional.
- If provided, treat it as an issue reference and support:
  - GitLab issue URL (`https://gitlab.com/<group>/<project>/-/issues/34`)
  - short reference (`#34`)
  - bare number (`34`)

## Required Workflow

1. Load and follow the `glab` skill guidance first.
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
5. Build an MR title using conventional commit style.
6. Build an MR description using this structure:

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
8. Create MR non-interactively with `glab mr create` using the generated title and description.

## Output

Return:

- created commit hash/message (or note that no commit was needed)
- MR URL
- final issue-closing line used (if any)
