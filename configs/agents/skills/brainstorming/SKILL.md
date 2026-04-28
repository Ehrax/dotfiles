---
name: brainstorming
description: Use only when the user explicitly asks to brainstorm, think through an idea, explore options, workshop an approach, or says phrases like "let's brainstorm", "let's think about it", "help me design this", or "what are my options"; do not use for direct implementation, fix, edit, or change requests
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs through natural collaborative dialogue, with optional written specs when they are useful or requested.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<TRIGGER>
Manual intent only. Use this skill only when the user explicitly asks to brainstorm, think through, workshop, explore options, or design before implementation.

Do not infer brainstorming intent from requests like "implement", "fix", "change", "edit", "add", "update", "refactor", "make this work", or "do X". Those are direct work instructions unless the user also asks to brainstorm first.

If this skill was loaded for a direct implementation request, stop following it and proceed with the requested work normally.
</TRIGGER>

## When Active

When the user explicitly starts a brainstorming/design conversation, do not invoke any implementation skill, write code, scaffold a project, or take implementation action until you have presented a design and the user has approved the next step.

## Non-Triggers

Do not use this skill for:
- Direct implementation instructions
- Bug fixes or debugging requests
- Config edits
- Code review requests
- Small targeted changes where the user already stated what to do
- Follow-up requests that continue an already chosen implementation path

## Checklist

Create tasks for the required discovery and design items. Create documentation or planning tasks only when the user chooses them.

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get user approval after each section
5. **Offer next step** — ask whether the user wants a written spec or direct implementation
6. **If spec requested:** write and review the spec, then ask whether to implement
7. **If direct implementation chosen:** proceed using the appropriate implementation skill or normal coding workflow

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Want written spec?" [shape=diamond];
    "Write design spec" [shape=box];
    "Spec self-review\n(fix inline)" [shape=box];
    "User reviews spec?" [shape=diamond];
    "Proceed to implementation" [shape=doublecircle];

    "Explore project context" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Want written spec?" [label="yes"];
    "Want written spec?" -> "Write design spec" [label="yes"];
    "Want written spec?" -> "Proceed to implementation" [label="no"];
    "Write design spec" -> "Spec self-review\n(fix inline)";
    "Spec self-review\n(fix inline)" -> "User reviews spec?";
    "User reviews spec?" -> "Write design spec" [label="changes requested"];
    "User reviews spec?" -> "Proceed to implementation" [label="approved"];
}
```

**After design approval, ask the user:** "Want me to write a spec, or jump straight to implementation?"

If they want a spec, write it and ask for review. If they skip it, proceed directly to implementation using the appropriate skill or normal coding workflow.

## The Process

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single pass, help the user decompose it into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets an approved design, then optionally a written spec based on user preference.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

**Optional Documentation:**

- Ask whether the user wants a written spec before creating one.
- If requested, write the validated design/spec to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  - (User preferences for spec location override this default)
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document only when the user asked for a saved spec or commit

**Spec Self-Review:**
If you write a spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for direct implementation, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review — just fix and move on.

**User Review Gate:**
If you wrote a spec and the spec review loop passes, ask the user to review it before proceeding:

> "Spec written to `<path>`. Please review it and let me know if you want changes. After that we can implement directly."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

**Implementation:**

- Proceed directly to implementation after the approved design, or after the optional spec is approved.

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense
