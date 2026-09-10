---
name: code-review
description: Review a PR, branch or working changes for correctness, documented standards and the agreed requirements. Use for a requested code review or review since a named ref; a tracker and parallel agents are optional.
---

Review the requested change from two perspectives:

- **Standards** — does the code conform to this repo's documented coding standards?
- **Spec**: does the code correctly implement the agreed behavior, including relevant failure paths?

Do both passes directly by default. Use parallel subagents only when the user requests delegation and the passes can run independently. An issue tracker is optional; the conversation can supply the requirements.

## Process

### 1. Pin the fixed point

Use the user's explicit scope. Otherwise infer it from the active task or PR and state the comparison; ask only if genuinely different scopes remain plausible.

- PR or branch changes: resolve the base and head to commit IDs and use their merge-base diff, recording the commits.
- “Since commit X”: compare X to the requested endpoint; use a merge-base only when that matches the request.
- Uncommitted work: inspect staged and unstaged diffs plus relevant untracked files. `git diff HEAD` covers tracked working changes but omits untracked files.

Record the commands and file scope. Validate refs before use. An empty tracked diff is not proof that an explicitly requested untracked file has no changes. If there is no reviewable change, report that without creating a branch or changing the index.

### 2. Identify the requirements source

Use the user's request and accepted decisions, any explicitly supplied spec, or the originating issue/PR and relevant repo documentation. Fetch linked tracker content through an available authorized reader when needed; no tracker setup is a prerequisite.

If requirements are missing, continue the correctness and standards review and report the limit on requirement coverage. Ask only when a specific ambiguity prevents assessing an important behavior. Do not invent requirements.

### 3. Identify the standards sources

Anything in the repo that documents how code should be written, such as `CODING_STANDARDS.md` or `CONTRIBUTING.md`.

Use the following Fowler code smells (_Refactoring_, ch.3) as optional prompts when they reveal a concrete maintenance problem in the change. They are not a quota or an automatic refactoring requirement:

- **The repo overrides.** A documented repo standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation — and, like any standard here, skip anything tooling already enforces.

Each smell reads *what it is* → *how to fix*; match it against the diff:

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, or hooks added for needs the spec doesn't have. → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

### 4. Review both perspectives

Perform the standards pass and the requirements pass yourself. If the user requested parallel review, give each agent the fixed comparison and necessary sources using the briefs below. Do not present two passes by one agent as independent review.

- **Standards:** inspect the changed code and relevant callers for documented-rule violations and concrete maintenance problems. Cite the rule and affected hunk; distinguish violations from judgment calls. Skip findings already enforced by tooling.
- **Requirements and correctness:** check the agreed behavior, relevant failure paths, missing or partial requirements, and changes outside the request. Tie each finding to evidence; conversation requirements are valid even without a spec file.

For delegated review, include the resolved comparison, relevant requirements and standards, and enough caller context for each pass. If no requirements are available, continue correctness review and state that limit.

### 5. Aggregate

Report actionable findings in severity order with file/line evidence, the affected behavior and the requirement or standard where applicable. Deduplicate overlapping findings and label subjective maintainability suggestions as such. Keep both perspectives visible without requiring two verbatim reports or a fixed response length.

State what was actually inspected or run and any coverage limit. If there are no actionable findings, say so; do not manufacture smells. Review alone does not authorize fixes, publication or commits.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
