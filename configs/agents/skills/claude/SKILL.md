---
name: claude
description: Drive the Claude Code CLI to delegate work to a Claude model — headless runs via `claude -p`, model selection (opus/sonnet), resuming sessions. Use when you are NOT a Claude model yourself and the task needs taste (UI, copy, API design, code review) or an independent second perspective, or when the user says to hand work to Claude.
---

# Claude Code CLI

Delegate work to Claude and stay the foreman: you scope the job, Claude executes headlessly, you verify and integrate. Mirror of the `codex` skill, pointed the other way.

Verified against `claude 2.1.201` — on a version bump, re-check flags with `claude -p --help`.

## When to reach for Claude instead of doing it yourself

Consult the project AGENTS.md model table ("Picking models for delegated work"). Default driver split: gpt-5.5 drives backend and logic work; **Claude drives frontend/visual work** (UI, copy, API design — taste ≥ 7 → opus-4.8, sonnet-5 as budget option). Also: an independent review of your own plan or diff needs a fresh session — a fresh Claude run qualifies; your own session never does.

## Launch

```bash
cd <repo-or-worktree> && claude -p "<brief>" --model opus --permission-mode acceptEdits --output-format json > "$SCRATCH/claude-last.json"
```

- `-p` = headless: runs the task, prints the result, exits. cwd = workspace. There is no `-o` flag — capture stdout.
- `--model opus | sonnet` — aliases resolve to the latest version; pick per the model table.
- `--output-format json` returns one JSON object: `result` (final message), `session_id` (needed to iterate), `total_cost_usd`, `is_error`, and `permission_denials`.
- **Permission modes (verified behavior):** `acceptEdits` lets Claude create/edit files unattended. Default mode fails CLOSED headlessly — a Write is denied, recorded in `permission_denials`, and the file is never created. Use default mode + "FINDINGS ONLY, do not edit" for read-only reviews: it is enforced, not just requested.
- Claude auto-reads CLAUDE.md/AGENTS.md and loads this same shared skills folder — don't restate what's already there; a brief may tell Claude to use a skill by name.
- Runs on real tasks take minutes — launch in the background and poll for the output file rather than blocking. Trivial calls return in ~5s.

## The brief

Same anatomy as any executor brief (see the `orchestrate` skill): one-sentence goal, context pointers, pinned goldens, scope fence, done-when, verification duty, report format. For UI work attach the reference by file path in the brief and require a screenshot-vs-reference comparison before reporting done.

## Verify, then iterate — resume, don't restart

`is_error: false` ≠ task done: read `result`, inspect `git diff`, run the brief's verification command yourself.

```bash
claude -p --resume <session-id> "<feedback>" --output-format json   # keeps full context
claude -p -c "<feedback>"                                           # most recent session in this cwd
```

- Resume keeps the SAME `session_id` across turns (unlike codex, which mints new ones) — one id per delegation, reuse it for every iteration.
- Resume needs `--model` re-passed if you want a non-default model; permission mode is also re-passed per call.
- Work already on disk survives a killed run — resume instead of redoing.

## Gotchas

- Parallel Claude runs that write files need one git worktree each — concurrent writers in one checkout conflict.
- `--dangerously-skip-permissions` exists but don't reach for it headlessly; `acceptEdits` covers implementation work.
- Never let the same Claude session that implemented a change also review it — reviews get a fresh session (new `claude -p`, not `--resume`).
- Plain-text output (no `--output-format json`) is just the final message — fine for one-shots, but you lose the session id and the denial log.
