---
name: mobile-qa-runner
description: Run or author goal-driven mobile QA missions with the private Jev and Maestro mobile QA runner. Use this skill whenever the user asks an agent to test, verify, explore, or hand off an iOS or Android app flow through mobile-qa-runner, Jev, Maestro, a project QA mission, or a plain-language mobile goal, even when they only say to check the app like a user.
compatibility: Requires Node 24+, pnpm 11, Maestro MCP, a booted mobile device or Simulator, and a local checkout of the private mobile-qa-runner package.
---

# Mobile QA Runner

Use the private `@ehrax/mobile-qa-runner` package as the execution engine. Keep app-specific flows in
the app repository. The package owns the loop, action registry, confidence gates, adapters and
reporting; the project owns its app identity, goals, expected visible outcomes and approved inputs.

Jev is a classifier inside a code-owned loop. It chooses among concrete actions generated from the
current accessibility state. Do not give Jev unrestricted MCP tools or ask it to generate text.

## Discover the project contract

1. Read the repository's `AGENTS.md` and follow its runtime and Git boundaries.
2. Look for `qa/mobile/README.md`, `qa/mobile/*.json`, and a `qa:mobile` package script.
3. Read the project's mobile QA README and the selected mission before starting a device action.
4. Treat the mission as the authorization boundary. Input text is permitted only when it is declared
   under `inputs` and exposed by the current stage through `allowedInputs`.
5. If the requested test would send, publish, purchase, delete, or otherwise mutate external state
   beyond what the user plainly requested, pause for authorization instead of broadening the flow.

Prefer the project's launcher because it owns local environment paths and report placement:

```sh
pnpm qa:mobile --list
pnpm qa:mobile validate <mission-name>
pnpm qa:mobile <mission-name>
```

When no launcher exists, find the private runner checkout with the repository's project-resolution
convention, build it, and run its CLI with an absolute mission path. Do not copy the runner source
into the app repository.

## Author a project mission

Create a versioned mission in the project's established mobile QA directory when the flow should be
repeated. Reuse the app block and naming conventions from a nearby mission.

Shape the flow as a small sequence of observable stages:

- `goal` says what the user accomplishes next, without tap coordinates or implementation details.
- `success` describes evidence visible in the current accessibility state.
- Keep each stage local enough that Jev can choose the next action literally.
- Put exact permitted text in top-level `inputs`; never ask Jev to invent it.
- Add the input ID to `allowedInputs` only on the stage where it may be entered.
- Use `successWhen.visibleText` when exact text is deterministic evidence.
- Add `successWhen.editable: false` when text in a composer must not count as a rendered result.
- Retain the default `0.75` action and success thresholds unless observed evidence justifies a
  mission-specific change.
- Give long flows explicit stages and a finite step budget instead of one broad paragraph.

Example:

```json
{
  "version": 1,
  "id": "open-listing-and-contact-seller",
  "app": {
    "platform": "ios",
    "applicationId": "com.example.marketplace.dev",
    "launch": "never"
  },
  "stages": [
    {
      "id": "listing",
      "goal": "Open any visible board listing.",
      "success": "A board detail screen with a Contact seller action is visible."
    },
    {
      "id": "conversation",
      "goal": "Open the seller conversation.",
      "success": "A message composer and Send message action are visible."
    },
    {
      "id": "compose",
      "goal": "Enter the approved interest message.",
      "success": "The composer contains the complete approved message.",
      "allowedInputs": ["interest-message"]
    },
    {
      "id": "send",
      "goal": "Send the composed message.",
      "success": "The sent message is visible as a non-editable conversation bubble.",
      "successWhen": {
        "visibleText": "Hi! Is this board still available?",
        "editable": false
      }
    }
  ],
  "inputs": {
    "interest-message": {
      "description": "the approved purchase-interest message",
      "text": "Hi! Is this board still available?",
      "targetText": "Message"
    }
  }
}
```

Validate a new or changed mission before running it. Keep the flow in the project; do not add its
screen labels, app ID or expected copy to the generic runner package.

## Prepare and run

Honor the mission's launch policy:

- `launch: "never"` means the intended app must already be foregrounded. Starting anywhere inside
  the app is valid; Jev derives the next action from the current tree.
- `launch: "always"` lets the driver launch the declared application ID before observation.

Reuse an existing mobile runtime. Do not start duplicate Metro, API, emulator, or Simulator
processes. Set `MAESTRO_DEVICE_ID` when multiple matching devices are connected. Never print API
keys or copy environment files into a report.

Run one mission at a time against a device. The accessibility state and external side effects are a
shared mutable resource, so concurrent missions are not independent.

## Read the verdict

Read the generated `result.json`; do not infer success from Jev selecting `done`, a successful tap,
or the final screenshot alone.

- `passed`: every stage has visible success evidence.
- `inconclusive`: confidence, repetition, a blocking state, or explicit escalation stopped the loop.
- `budget_exhausted`: the mission reached its step budget without establishing all stages.
- `failed`: an adapter, device, API, or runner operation failed.

Report the mission, status, reason, completed stages, report path, and whether runtime evidence was
actually captured. Keep source validation, functional device proof, and visual acceptance distinct.
When the result is not `passed`, preserve the trace and explain the stopping condition rather than
bypassing the gate or manually completing the flow behind the runner.
