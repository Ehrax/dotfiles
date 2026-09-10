---
name: diagnosing-bugs
description: Diagnose unclear, recurring or unsuccessfully repaired bugs and performance regressions using reproducible evidence. Use for an explicit diagnosis request or when the cause remains uncertain; ordinary fixes with a clear cause do not need this workflow.
---

# Diagnosing Bugs

A diagnosis loop for hard bugs. Scale the investigation to the uncertainty: a clear local cause may need one hypothesis and a targeted check; repeated failed fixes need stronger reproduction and comparison evidence.

When exploring the codebase, read `CONTEXT.md` (if it exists) to get a clear mental model of the relevant modules, and check ADRs in the area you're touching.

## Phase 1 — Build a feedback loop

Establish a signal that can detect the user's exact symptom. Read relevant code and form provisional hypotheses as needed to build the reproduction; distinguish these from a demonstrated cause.

Choose the cheapest adequate signal:

- A failing test, CLI fixture or HTTP request through the affected path.
- A repeatable browser or native UI sequence with initial state, running build/device, actions and expected versus observed behavior. A screenshot, recording or targeted measurement can capture the result.
- A captured trace, small harness, differential comparison or bisection when isolation would resolve uncertainty.
- Human-assisted steps when the agent cannot operate the relevant environment. `scripts/hitl-loop.template.sh` is optional, not the only permitted form of UI evidence.

Prefer automation when it improves reliability. A native interaction does not require a shell wrapper or a unit test before it can be investigated. Keep captured data minimal and redacted.

### Tighten the loop

Treat the loop as a product. Once you have _a_ loop, **tighten** it:

- Can I make it faster? (Cache setup, skip unrelated init, narrow the test scope.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time, seed RNG, isolate filesystem, freeze network.)

Reduce setup cost where practical without substituting a simpler scenario that misses the bug. Native launches and environment-dependent failures may take minutes.

### Non-deterministic bugs

Record the failure rate and conditions over a bounded number of attempts. Use repeated triggers, stress or timing probes when they help distinguish causes; do not require a particular failure rate. Coordinate shared runtimes and avoid uncontrolled load. A few clean runs do not prove an intermittent failure is fixed.

### When you genuinely cannot build a loop

State what could and could not be observed. Continue safe code inspection, artifact analysis and targeted checks that can narrow the cause. Ask only for missing access or evidence that blocks further progress; production instrumentation needs appropriate authorization. Do not claim a reproduced or verified fix without that evidence.

### Completion criterion: a symptom-specific signal

Record the command or UI sequence actually run, its relevant initial state, and the observed result. It must exercise the user's failure path and distinguish failure from success. For intermittent bugs, record attempts and failures. If only static evidence is available, label that limit and keep hypotheses provisional.

## Phase 2 — Reproduce + minimise

Run the loop. Watch it go red — the bug appears.

Confirm:

- [ ] The loop produces the failure mode the **user** described — not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] Record whether the failure repeated and, for intermittent bugs, the number of attempts and failures.
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

### Minimise

When it would help distinguish causes, shrink the reproduction while retaining the user's failure path. Remove one irrelevant input or step at a time and rerun it.

Why bother: a minimal repro shrinks the hypothesis space in Phase 3 (fewer moving parts left to suspect) and becomes the clean regression test in Phase 5.

Stop minimising when the evidence is sufficient to test the likely cause. Full minimisation is not a gate for a clear local fix.

## Phase 3 — Hypothesise

Start with the most plausible falsifiable hypothesis. Compare alternatives when the evidence is ambiguous or a prior fix failed; do not invent a fixed number of theories.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe — discard or sharpen it.

Briefly state the leading hypothesis and the next discriminating check when useful. Continue within the authorized scope; no routine approval checkpoint is required.

## Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

**Performance.** Establish a baseline timing, profile or query plan before changing the suspected bottleneck. Use bisection when a known regression range makes it useful; compare the same workload after the fix.

## Phase 5 — Fix + regression test

When a durable regression test would add meaningful coverage and has a correct seam, write it before the fix. A repeatable UI check or measurement can be sufficient for a small visual repair; do not add tests that merely mirror the implementation.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (single-caller test when the bug needs multiple callers, unit test that can't replicate the chain that triggered the bug), a regression test there gives false confidence.

If automation cannot cover the symptom, document the verification method and its limit. That alone does not prove an architectural defect or authorize a refactor.

If adding a meaningful regression test:

1. Turn the minimised repro into a failing test at that seam.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

## Phase 6 — Cleanup + post-mortem

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Relevant regression check passes; any untested path is explicit
- [ ] Temporary instrumentation added by this task is removed (`rg` the prefix)
- [ ] Temporary artifacts from this task are removed or retained in a clearly marked debug location; unrelated work is preserved
- [ ] Report the established cause, actual verification and remaining uncertainty. Include them in a commit / PR only if that action is part of the user's request

**Then ask: what would have prevented this bug?** If the answer involves architectural change (no good test seam, tangled callers, hidden coupling) hand off to the `/improve-codebase-architecture` skill with the specifics. Make the recommendation **after** the fix is in, not before — you have more information now than when you started.
