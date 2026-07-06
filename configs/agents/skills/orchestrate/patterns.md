# Fan-out patterns & steering

Load this when running MULTIPLE agents — single delegations only need SKILL.md.

## Fan-out patterns

- **Contract first, then fan out.** When slices share types or interfaces (parser feeds store feeds render), pin the shared contract as compiling stubs/signatures in ONE fast step before parallelizing — downstream slices code against the stubs with fakes, never against another slice's in-flight work. Skipping this turns "independent" slices into an integration lottery.
- **Independent slices → parallel worktrees.** Non-overlapping file ownership per agent; the scope fence is what makes parallelism safe. You arbitrate merges: "main has moved — merge it in, preserve BOTH behaviors: X from main, Y from your branch."
- **Worktree lifecycle (mandatory for every writing executor):** create branch + worktree → executor works there → verification passes → merge/PR back → REMOVE the worktree and delete the merged branch in the same step. Merge-back and cleanup are one atomic move — a merged-but-lingering worktree is a stale-state trap for the next run. Bake the cleanup into the brief ("clean up your worktree when done") AND verify it yourself; orphaned worktrees from killed runs are recovered (see Steering), not deleted.
- **Pipeline, not barrier.** Slice A can be in review while slice B is still implementing. Only synchronize when a step genuinely needs ALL prior results (dedupe, "zero findings → skip verification").
- **Review = separate agent, separate role.** Never let the implementer review itself. Reviewers are read-only ("do not edit, stage, or commit"), get the exact diff range (`git diff <sha>..HEAD`), a named rubric, and a priority order ("data-loss, idempotency, security first — no praise, findings only, file:line").
- **Adversarial verify for judgment calls.** For "is this finding real?" spawn 2–3 skeptics prompted to REFUTE it; majority wins. Diverse lenses (correctness / security / does-it-reproduce) beat identical duplicates.
- **Loop until dry, not until N.** For discovery work (bugs, audit findings), keep spawning finders until two consecutive rounds return nothing new. Exit condition for fix loops: "two consecutive clean review passes."

## Steering running agents

- Status checks that don't derail: "Brief progress + ETA. Do not widen scope."
- A run that's missing a required input (screenshots, spec) gets killed and restarted with the input — don't let it limp forward.
- Recovery brief after a crash: "Your edits are already on disk — verify and continue, do not redo. Remaining per the original brief: (1)… (2)…"
