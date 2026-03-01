---
name: commit
description: Commit all current changes as a single conventional commit. Use when the user asks to commit everything quickly and safely.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*)
---

# Commit All Changes

Create exactly one git commit that includes all current tracked and untracked changes.

## Rules

- Follow conventional commits (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `build`, `ci`, `perf`, `style`, `revert`).
- Prefer a scope when clear (`feat(auth): ...`).
- Write a concise message focused on intent and impact.
- Do not amend unless the user explicitly asks.
- Never add extra explanatory text before running tool calls.

## Execution Steps

1. Run these commands to inspect context:
   - `git status`
   - `git diff HEAD`
   - `git branch --show-current`
   - `git log --oneline -10`
2. If there are no changes, report that there is nothing to commit and stop.
3. Stage everything with `git add -A`.
4. Create one conventional commit message based on all staged changes.
5. Run `git commit -m "<message>"`.
6. Run `git status` to confirm the result.

## Output

Return:

- commit hash and message
- short rationale for the chosen conventional type/scope
- final git status summary
