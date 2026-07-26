# Harness mechanics — how to actually dispatch executors

The playbook (SKILL.md) is harness-independent. This file maps it to each environment. Load only the section for the harness you are running in.

## Codex Desktop (GUI threads)

- One thread = one executor. Paste the full brief as the thread's FIRST message — the brief IS the thread's contract; later messages are steering only.
- Parallel slices: one thread per slice, each pointed at its own git worktree in the brief's scope fence.
- Reviewer = a NEW thread (fresh context = independence), never a follow-up message in the implementer's thread.
- Threads keep context across your steering messages — use the status-check and recovery templates from patterns.md as messages, not new threads.

## codex CLI (headless)

- `codex exec -C <worktree> -s workspace-write -o <out.md> "<brief>" </dev/null` — one exec per worktree.
- Reviewer: `codex exec -s read-only` in the same worktree with the diff range + rubric; or `codex review --base <branch>` for the quick built-in pass.
- Iterate with `codex exec resume --last "<feedback>"` — resume keeps context, a fresh exec throws it away.
- Exit 0 ≠ done: read the `-o` file, run the brief's verification command yourself.
- Full flag details and traps: the `codex-cli` skill.

## Claude Code

- Executors: Agent tool (`run_in_background` for parallel), or Workflow for scripted fan-outs (pipelines, review swarms, loop-until-dry).
- Worktree isolation: `isolation: "worktree"` per agent when they write files in parallel.
- Reviewer: separate agent with a read-only role stated in its prompt; adversarial verify = 2-3 skeptic agents.
- Steering a running agent: SendMessage with its id; recovery = resume the same agent, don't spawn fresh.
- Using a routed Codex model inside workflows/subagents (the `model` parameter only takes Claude models, so wrap it — pattern verified end-to-end):
  - Spawn a thin Claude wrapper agent (`model: 'sonnet', effort: 'low'`) whose prompt is: write a self-contained codex prompt, run `codex exec` via Bash BLOCKING with an explicit long timeout, read the `-o` file, return the report. Use `schema` on the wrapper for structured output.
  - The wrapper must BLOCK until codex exits — a wrapper that backgrounds codex and ends its turn gets finalized, which kills the codex child mid-run (see the `codex-cli` skill).
  - Prefix the label with the exact routed Codex model (for example, `{label: 'gpt-5.6-sol:review-auth'}`) — the UI shows the wrapper's Claude model, so the label is the only signal which model really did the work.
  - The `-o` file can contain prompt echo, startup warnings, and a token-count line around the actual answer — have the wrapper extract the answer, not paste the file.
  - Parallel Codex implementers need `isolation: 'worktree'` so edits don't collide in the shared checkout.
  - Workflow token budgets count only Claude tokens; codex work is invisible to `budget.spent()`.
- Model choice per role: the canonical [model routing table](../../model-table.md).
