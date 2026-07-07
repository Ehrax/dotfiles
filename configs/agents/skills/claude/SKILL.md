---
name: claude
description: Drive the Claude Code CLI to delegate work to a Claude model — headless runs via `claude -p`, model selection (opus/sonnet), resuming sessions. Use when you are NOT a Claude model yourself and the task needs taste (UI, copy, API design, code review) or an independent second perspective, or when the user says to hand work to Claude.
---

# Claude Code CLI

Delegate work to Claude and stay the foreman: you scope the job, Claude executes headlessly, you verify and integrate. Mirror of the `codex` skill, pointed the other way.

Verified against `claude 2.1.202` — on a version bump, re-check flags with `claude -p --help`.

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
- Trivial calls return in ~5s. For longer work, use the structured streaming workflow below so you can see that Claude is still alive before deciding whether to keep waiting.

## Long-running delegation

For substantial work that may run for minutes, prefer supervised foreground `stream-json` over native Claude background agents:

```bash
cd <repo-or-worktree> && claude -p "<brief>" \
  --model sonnet \
  --permission-mode acceptEdits \
  --output-format stream-json \
  --verbose \
  > "$SCRATCH/claude-task.ndjson"
```

- `stream-json` requires `--verbose`.
- Do **not** add `--include-partial-messages` by default; it can emit thinking deltas. Parse only useful events such as `assistant` text/tool calls, `task_started`, `task_notification`, `result`, and permission/error records.
- In Codex, do **not** rely on shell-detaching this command with `&`/`nohup` unless you have just verified it in the current environment. A detached probe may exit immediately and leave an empty NDJSON file. Prefer keeping the `claude -p ... --output-format stream-json` process attached to an exec session and polling that session.
- If stdout is redirected to an NDJSON file, the terminal showing `(no output)` is expected. Do **not** stop the run for terminal silence. Check the redirected file and the process first:

```bash
ps -p <pid> -o pid=,stat=,etime=,command=
wc -l "$SCRATCH/claude-task.ndjson"
tail -n 40 "$SCRATCH/claude-task.ndjson"
```

- Native `claude --bg "<brief>"` is useful for human attach/inspect flows (`claude agents`, `claude attach`, `claude logs`), but it conflicts with `-p/--print`; you do not get a clean JSON result. `claude logs <id>` is terminal UI output with escape sequences, not a stable parser interface.
- Poll the NDJSON file while the process runs. Once you see a `task_started` event or growing NDJSON line count, silence can be normal: Bash stdout often appears only in the final `tool_result`, not line-by-line. Keep waiting until `task_notification`, final `result`, process exit, a permission denial, or an explicit timeout from the brief.
- For implementation tasks, no visible `git diff` yet is not proof that Claude is stuck. Claude may still be reading, planning, or running checks. Only interrupt after inspecting the stream/process state and seeing no meaningful activity past the agreed timeout.
- For very long tasks, require Claude to write a final report artifact under `$SCRATCH` (for example `$SCRATCH/claude-report.md`) in addition to its final response. This gives you a recovery path if the supervising process loses context.
- Tell Claude to avoid standalone sleeps while waiting. Claude Code may block them; for long commands it should use the CLI's normal tool behavior or its own background/monitor facilities and report the command, task id, and output path when available.
- Bash permission and command-shape guards can still fire with `acceptEdits` (for example complex loops, `bash -c`, or shell expansion). This is a feature of the stream: you can see the denial mid-run. If the task depends on specific commands, either keep them simple and literal in the brief or pass a narrow `--allowedTools` pattern for the expected checks.

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
