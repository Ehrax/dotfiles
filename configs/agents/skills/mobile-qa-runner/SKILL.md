---
name: mobile-qa-runner
description: Run or author goal-driven mobile QA missions with the private Jev mobile QA runner (native agent-device or Maestro driver). Use this skill whenever the user asks an agent to test, verify, explore, or hand off an iOS or Android app flow through mobile-qa-runner, Jev, Maestro, agent-device, a project QA mission, or a plain-language mobile goal, even when they only say to check the app like a user.
compatibility: Requires Node 24+, pnpm 11, a booted mobile device or Simulator, a local checkout of the private mobile-qa-runner package, and either a T3 device_open session (agent-device) or Maestro MCP.
---

# Mobile QA Runner

Use the private `@ehrax/mobile-qa-runner` package as the execution engine. Keep app-specific flows in
the app repository. The package owns the loop, action registry, confidence gates, adapters and
reporting; the project owns its app identity, goals, expected visible outcomes and approved inputs.

Jev is a classifier inside a code-owned loop. On every step the runner reads the accessibility
tree, builds a menu of concrete actions (tap this element, enter this approved input, scroll, wait,
done, escalate) and asks Jev to pick one. Jev reads that menu and the stage text literally and
cannot see pixels. A run succeeds when (1) the UI exposes what a user sees and (2) each stage names
one next step and a checkpoint that the tree can prove. Most failed runs broke one of those two, not
the model.

## Discover the project contract

1. Read the repository's `AGENTS.md`/`CLAUDE.md` and follow its runtime and Git boundaries.
2. Read `qa/mobile/README.md` (driver setup, launch policy, app-specific checkpoints) and the
   selected mission before any device action.
3. Treat the mission as the authorization boundary. Input text is permitted only when it is declared
   under `inputs` and exposed by the current stage through `allowedInputs`.
4. If the test would send, publish, purchase, delete, or otherwise mutate external state beyond what
   the user plainly requested, pause for authorization instead of broadening the flow.
5. One run owns the device. Check for another thread's device session or runner lock before
   starting, and coordinate instead of closing it silently.

Prefer the project's launcher:

```sh
pnpm qa:mobile --list
pnpm qa:mobile validate <mission-name>   # schema errors and WARN: authoring advice
pnpm qa:mobile <mission-name>
```

## Choose the driver

On iOS use the native agent-device driver when a T3 `device_open` session is available: set
`MOBILE_QA_DRIVER=agent-device`, `MOBILE_QA_DEVICE_COMMAND` to the returned executable and
`MOBILE_QA_DEVICE_ARGS` to a JSON array of exactly the returned target flags. It reports native field
types (inputs without placeholders work), covered and partly covered controls, targets behind the
keyboard, and back-button/tab/segment roles. Maestro's iOS tree has none of these: fields are
recognized only by placeholder, and taps land through floating bars. Maestro does report tab and
segment selection, which agent-device lacks. Use Maestro on Android or when a stage can only be
proven by selection state.

`launch: "always"` cold-starts the app (both drivers) and gives every run the same entry screen.
Use `launch: "never"` only for chained missions or a deliberately prepared start screen, and then
establish that state before the run, deterministically.

## Prepare the UI

The runner sees only the accessibility tree. When a stage stalls, first check whether the tree says
what the screen shows. Fix gaps in the app, not with mission workarounds:

- Every actionable control has an accessible label that names its action and target ("Open Surfers
  Lab public profile", "Save Classic Log 9'4"). Icon-only controls need one too.
- Labels never contain internal names (route groups such as `(tabs)`, component or testID names,
  SF Symbol names). Jev offers them as-is and cannot interpret them.
- Controls sharing a label are distinguishable by role or text (a back button titled "Sign in" and a
  "Sign in" segment are fine natively; two identical buttons are not).
- Text fields expose their label and current value. Secure fields expose bullets; that is enough.
- Checkpoint copy is stable. Put variable parts (prices, names, counts) after a stable prefix so a
  mission can use `textStartsWith`.
- Selection of custom chips/toggles is also visible in text or value (for example "New, selected" or
  a heading that changes), because native snapshots may omit selection state.
- Floating bars and sticky buttons cover content; that is fine because the native driver reports it.
  Do not rely on a control that stays under a permanent overlay.
- Loading states have recognizable text ("Loading listing"); Jev waits on them.

## Write goals Jev can follow

`goal` = the one thing to do next, named by visible label. `success` = what the tree shows when it is
done. `successWhen` = the code-checked proof. Each stage should be answerable by looking at one screen.

Rules, each from a stalled run:

1. **One action per stage.** "Open the layer menu and choose Shapers" → two stages.
2. **Name controls by label, never by position.** "Tap Map shows All", not "the button at the bottom
   right" (it was at the top; Jev escalated).
3. **No conditions or narrated preconditions.** Jev decides one step at a time. "If signed in, sign
   out" and "Start with Settings open" belong in setup or `launch`, or in their own stage.
4. **Prove success with text the tree contains.** Give every stage a `successWhen` when a stable text
   exists. A stage with `successWhen` is checked in code before Jev is asked, so an already-met stage
   costs nothing.
   - `visibleText` is an exact match: "Contact seller" never matches `Contact seller €600`. Use
     `textStartsWith` or a different stable anchor (for example "Share board" for a detail screen).
   - `editable: false` when the same text in a composer must not count.
   - `inputsVerified: true` for a stage that only enters approved input; it completes on readback
     without another model call.
   - `visibleText` + `scrollTo: true` when the text is further down the same screen; the driver then
     searches in one command. Never use it when the text appears only after navigating.
5. **Never rely on appearance or state the tree lacks:** colors, badges, order, map-marker styling,
   and (natively) which tab or segment is selected. Prove the effect through content it reveals.
6. **Success must be observable.** "Nothing has been submitted" cannot be seen; drop it or give the
   non-submission its own observable check.
7. **Say which route is under test.** When the entry point matters, make it a required stage so Jev
   cannot reach the goal another way.
8. **Enable gestures only where needed** (`gestures: ["swipe"]` for panning a map); every extra action
   is another option to choose from.
9. **Keep default gates** (action 0.75, success 0.75). `wait` already has its own lower gate.

Before and after:

```json
{ "id": "shapers", "goal": "Open the map layer menu at the bottom right and choose Shapers.",
  "success": "The layer button now reads Shapers and the map shows Shaper markers only." }
```

```json
[
  { "id": "layer-menu", "goal": "Tap the map layer button labelled Map shows All to open the layer menu.",
    "success": "The layer menu with the options All, Shops and Shapers is visible." },
  { "id": "shapers", "goal": "Choose Shapers in the open layer menu.",
    "success": "The layer button now reads Shapers.",
    "successWhen": { "visibleText": "Map shows Shapers" } }
]
```

Run `validate` after every change and address its `WARN:` lines or keep the wording deliberately.
Keep flows in the project; never add app labels, IDs or copy to the generic runner.

## Diagnose a stopped run

Read `result.json` before changing anything. For the last trace entry, look at:

- `candidates`: was the right action offered at all? If not, it is a UI or observation gap (missing
  label, field not editable, element covered) – fix the app or use the native driver.
- `decision.probabilities`: was the right action ahead but below 0.75, or did probability split
  between duplicates or equally valid targets? Tighten the goal to one target.
- the observation's elements: is the success text really there, exactly as written in `successWhen`?
- the stopping reason: "done without sufficient evidence" means the success text is not observable
  or not literal enough.

Change one thing, rerun once, and compare. Do not reword goals blindly for several rounds; print the
tree after the first unexpected stop. Report provider errors (HTTP 5xx) separately from product or
mission findings.

## Read the verdict

- `passed`: every stage has visible success evidence.
- `inconclusive`: confidence, repetition, a blocking state, or explicit escalation stopped the loop.
- `budget_exhausted`: the mission reached its step budget without establishing all stages.
- `failed`: an adapter, device, API, or runner operation failed.

Report the mission, driver, status, reason, completed stages, report path, and whether runtime
evidence was captured. Keep source validation, functional device proof, and visual acceptance
distinct. When the result is not `passed`, preserve the trace and explain the stopping condition
rather than bypassing the gate or completing the flow behind the runner.
