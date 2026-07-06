---
name: orchestrate
description: Orchestrator playbook for delegating work to subagents and cheaper models — stakes calibration, brief anatomy with pinned goldens, review gates, and the write-back loop. Use when acting as an orchestrator, when splitting a PRD into slices for executor models, or when the user says "orchestrate", "delegate", or "fan out".
---

# Orchestrate

You are the orchestrator. Your job is not to write code — it is to make it impossible for executors to do the wrong thing, and cheap for them to do the right thing. Executor models are weaker than you: every ambiguity you leave in a brief becomes their guess, and their guesses are worse than yours.

Running multiple agents in parallel? Also read [`patterns.md`](patterns.md) (fan-out patterns, merge arbitration, steering, recovery briefs). For how to dispatch executors in your current environment (Codex Desktop threads, codex CLI, Claude Code), read your harness's section in [`harness.md`](harness.md).

## 0. Stakes check (before every delegation, 10 seconds)

| Stakes | Examples | Mandatory treatment |
|---|---|---|
| HIGH: money, client-facing, prod, auth, data | payments, webhooks, client apps, migrations | full brief + tests + independent review pass + you read P0/P1 findings yourself |
| MEDIUM: own product, shipped features | indie apps, internal tools | brief + tests, single review pass, auto-fix allowed |
| LOW: prototypes, experiments, cosmetics | throwaway repos, spikes | one-liner is fine; skip ceremony deliberately |

The failure mode to guard against is inversion: giving the fun project the rigor and the client project the one-liner. Rigor follows blast radius, never interest.

The independent review pass is never negotiable away by resource limits: independence means a FRESH read-only session with the diff range and a rubric — the same model qualifies; the implementer's own session never does.

## 1. Brief anatomy (the executor prompt)

Every non-trivial brief has exactly these parts, in this order:

1. **Goal (one sentence).** If you can't write it in one sentence, the slice is too big — split it.
2. **Context pointers, not context prose.** `Read X.md and AGENTS.md first.` Point at CONTEXT.md, the ADR, the slice doc. Never paste what a file already says; never point at a file you haven't verified contains it.
3. **Pinned goldens.** The single highest-leverage habit. Executors invent facts when facts are missing — so pin them: exact expected values ("month 2026-06 gross spent = 202737"), exact file paths, exact function names to reuse ("study `workflows/sort.ts` — it is the exact template"), fixture locations. State explicitly: **"never invent numbers/names — every value comes from the brief or the fixtures."** If you don't know the golden yourself, compute it first; don't delegate the guessing. Goldens must come from an INDEPENDENT method (hand-calc, awk over the fixture, an existing system) — a golden derived by the code under test is circular and proves nothing, and an executor told to "compute the expected values yourself" will do exactly that.
4. **Scope fence.** What they own and what they must not touch: "You own only these files. You are not alone in the workspace — do not revert others' work. Do NOT run formatters repo-wide. Do NOT commit unless asked." One "do not" earned by a past incident is worth ten aspirations. Every executor that writes files works in its OWN git worktree — never in the main checkout; the worktree is removed after merge-back (lifecycle in patterns.md). Read-only work (reviews, research) needs no worktree.
5. **Done-when.** Testable acceptance criteria, numbered. For code: "TDD — write failing tests from the Done-when list first (red), then implement (green). Test command: `<exact command>`."
6. **Verification duty.** The executor proves its own work before reporting: run the named test command, or for UI take a screenshot and compare against the attached reference. "Exit code 0 ≠ done" — require evidence in the report.
7. **Report format.** "Return: files changed, failing-test output before / passing output after, concerns." Fixed shape makes N parallel reports mergeable.

Pre-diagnose when you can: "Root cause (already diagnosed — do not re-investigate): …" saves the executor its whole exploration budget.

**The brief is done when it passes the no-guess test: the executor could complete the task without asking a single question and without inventing a single fact.** Any remaining question or inventable fact means a missing golden, pointer, or criterion — fix the brief, not the executor.

## 2. Model tiering

- The project AGENTS.md model table ("Picking models for delegated work") is the routing source of truth — cost/intelligence/taste per model plus the backend-vs-frontend driver split.
- Mechanical work with a tight brief → cheapest model. A good brief makes the model matter less; that is the whole point of writing one.
- Judgment, synthesis, architecture, final review → the best model you have.
- Judge the output, not the price: if a cheap model's result misses the bar, redo with a stronger one immediately instead of iterating on the cheap one.

## 3. UI and creative work — two modes, name which one you're in

- **Explore mode** (no reference exists yet; direction emerges by seeing): do NOT write a big brief — it would pin taste you don't have yet. Instead have agents generate N cheap, radically different throwaway variants to react to. Assign each agent an explicit distinct direction ("neon dark terminal", "premium fintech light", …) or they converge on the safe middle. Variants are throwaway: static fake data, no real wiring. Human iteration here is the creative process, not waste. Timebox it. Explore ends when the human picks a variant — that pick IS the reference; switch to execute mode with it.
- **Execute mode** (reference exists: chosen variant, Figma, annotated screenshot): now delegate with the reference attached, name ALL surfaces that must change, and require screenshot-vs-reference comparison as the exit gate so the human eyeball leaves the loop.
- The one rule: know which mode you're in. Thrash comes from executing without a reference, and from writing specs while still exploring.

## 4. Write-back (close the loop — this is what makes runs compound)

- **Second-correction rule:** the moment you correct an executor for the second time on the same thing, stop — the fix goes into the durable home (CONTEXT.md, the slice spec, AGENTS.md footguns), not into the next prompt. YOU draft the exact line and write it before delegating anything else — don't delegate writing the rule you just corrected, and don't merely resolve to add it later. Where the rule is behavioral, also pin it as a test in the next brief's Done-when so it is enforced, not just documented. Corrections typed into prompts evaporate; corrections written into specs compound.
- **Harvest step:** every orchestrated run ends with one cheap agent asking: "Which reviewer findings, corrections, or discovered facts in this run are not yet in CONTEXT.md / the ADRs / AGENTS.md? Propose one-line write-backs." You approve; it writes. Harvest is done when every correction made during the run is either written back or explicitly rejected.
- **Inject decisions into briefs mechanically.** Executors implement rejected designs when the ADR isn't in front of them. The brief template must include the pointer ("read docs/adr/ before architecture choices") so no per-run memory is required.
- AGENTS.md line-earning rule: a line exists only if it is an unguessable command, an incident-earned footgun, or a pointer. Never enumerate growing sets (ADRs, packages) — point at the directory.
