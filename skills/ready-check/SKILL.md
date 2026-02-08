---
name: ready-check
description: Force reflection on understanding before acting. Use at session start after reading beads/CLAUDE.md, or before non-trivial implementation. Catches mechanical pattern-matching.
user-invocable: true
---

# Ready Check

> Invoke with `/ready-check` after reading beads and CLAUDE.md at session start, or before non-trivial implementation.

## Step 0: Pick Your Mode

| Situation | Mode |
|-----------|------|
| Session start, just read beads/CLAUDE.md | **Orientation** |
| Context switch to different part of codebase | **Orientation** |
| About to implement something non-trivial | **Implementation** |
| Caught yourself saying "straightforward" or "simple" | **Implementation** |
| Orientation flagged "needs deeper understanding" | **Implementation** |

---

# Orientation Mode

**Goal:** Verify understanding before acting on it. Context may be stale — verify before trusting.

**Exit:** "I've verified load-bearing parts. I know what I can trust and what needs checking."

## Step 1: Read Signposts

If `.claude/orientation.md` exists **in the workspace** (the project's `.claude/` folder, NOT `~/.claude/`), read it first — pointers from previous sessions.

**These are signposts, not truth.** Use them to know WHERE to look. Still verify.

## Step 2: State Your Understanding

1. **What is this project?** (One sentence)
2. **What's the architecture?** (Main components, state ownership)
3. **What's the current state?** (Done, in progress, blocked — from beads)

## Step 3: Identify Load-Bearing Context

What will you depend on being true for THIS work?

Examples:
- "CLAUDE.md says scraper uses crawl4ai — my changes depend on that"
- "The bead says statusline receives context percentage — implementation depends on that"

List specifically what's load-bearing. Not everything.

## Step 4: Verify Load-Bearing Context

| What I'm leaning on | How to verify | Verified? | If stale, what's true? |
|---------------------|---------------|-----------|------------------------|
| [context item] | [read file X, run Y] | Yes/No/Partial | [actual state] |

**When you find drift:** Update the source file so future sessions benefit.

## Step 5: Surface Remaining Assumptions

What's still unverified? List what remains uncertain — not to verify now, but to know where confidence is unearned.

**Check for verification gaps in handover docs:**

| Artifact Type | Look For | If Missing |
|---------------|----------|------------|
| Scripts/features created | "Tested: Yes/No" or verification status | Flag as "unknown if functional" |
| Spawned agents | "Insights captured" or debrief section | Flag as "context may be lost" |
| Open issues affecting work | "Blocking: Yes/No" judgment call | Flag as "blocker status unclear" |

**Why this matters:** Previous sessions may document WHAT exists without documenting WHETHER IT WORKS. "Script created" ≠ "Script tested." If verification status isn't explicit, surface it as an unknown.

## Step 6: Available Work Survey

| Task | What it involves | Major unknowns | Needs implementation-mode? |
|------|------------------|----------------|---------------------------|
| [task] | [scope] | [what I'd need to understand] | Yes/No |

**Verifiable vs. User-dependent:**
- Can I verify from code? Read it. Run it. Don't ask users to confirm facts you can observe.
- User input is for: goals, context, decisions — NOT factual things.
- Bead titles can be narrow. "Model downloaded" ≠ "integration works."

## Step 7: Update Signposts

Update the **workspace's** `.claude/orientation.md` (NOT `~/.claude/`) with load-bearing pointers discovered:
- File paths that answer specific questions
- Patterns identified
- Anything that eliminates wasted discovery time

Don't duplicate what's in CLAUDE.md or beads.

## Step 8: Output

```
**Orientation Complete**

Project: [one sentence]
Current state: [done/in progress/blocked summary]

Verified:
- [what you checked and confirmed]

Drift found and fixed:
- [what was stale, what you updated]
(or "None")

Verification gaps (from handover):
- [artifact]: unknown if tested
- [agent work]: insights not captured
- [blocker]: status unclear
(or "None — verification status was explicit")

Unverified assumptions:
- [what remains uncertain]

Available work:
- [Task A]: Ready / Needs implementation-mode first
- [Task B]: Ready / Needs implementation-mode first

Recommendation: [what to work on next]
```

---

# Implementation Mode

**Goal:** Genuine understanding — not just information — before building.

**Exit:** "I can trace from user goal to this implementation. I have what I need."

## Phase 1: Traceability Test (GATE)

**Core check. Everything else follows from this.**

> Can I trace backwards from what I'm about to build?

```
User goal: [What does the user actually want?]
    ↓
What must be true: [What needs to exist for that goal?]
    ↓
This implementation: [What I'm building, how it serves above]
```

**Test:** Can I explain why this matters to the user, what goal it serves, what breaks if I get it wrong?

**Failure-modes thinking:**

> What does bad look like? How does this fail?

Not a checklist — a **thinking prompt.** Engages with the problem through negative space.

- If you can identify some ways it could fail → you've thought about the domain
- If you can't identify ANY failure scenarios → red flag, you're pattern-matching mechanically

The negative (what bad looks like) helps infer the positive (what good must be).

### If you CAN'T trace:

**STOP.** Red flag. Possible causes:

| Symptom | Meaning |
|---------|---------|
| "I don't know what user goal this serves" | Work may have been invented by Claude |
| "Docs don't explain WHY" | Verbose but vapid |
| "Spec contradicts itself" | No coherent intent |
| "Inferring requirements from fragments" | Building on sand |

**Surface explicitly:**

> "I can't trace this to a clear user goal. [What's missing]. I don't have enough to build this well."
> "Want me to run `/dig` to find solid ground?"

**Do NOT proceed mechanically.**

### If you CAN trace:

State it briefly, proceed to Phase 2.

## Phase 2: Confidence Check

Phase 1 asked: "Does a chain exist?" This asks: "Is it solid or constructed from fragments?"

- Am I confident, or pattern-matching to make it fit?
- Am I papering over gaps?
- Am I treating assumptions as facts?

**If filling gaps:** Name what you're assuming before proceeding.

## Phase 3: Categorize Remaining Unknowns

### Implementation Decisions (Claude decides)

Technical choices requiring coding knowledge. Decide, but surface meaningful forks:

> "I'll use [approach]. This means [consequence]. Alternative: [other] → [different consequence]. Shout if that matters."

Only surface when there's a meaningful fork with ripple effects. 90% of the time: just decide.

### Behavior Decisions (User decides)

What the app DOES, not how it's built:

> "Need your input: [question in plain language]"
> "Assuming: [what you'll do if no response]"

### Constraints You're Inferring

> "Treating as constraints: [list]. Correct me if wrong."

## Phase 4: Checkpoint

```
**Ready Check: [Task Name]**

**Traceability:**
User goal → [what they want]
This serves it by → [how implementation helps]

**What does bad look like:**
- [failure scenarios, error states, edge cases]

**Implementation approach:**
- [Decision]: [What I'll do]. [Ripple if relevant].

**Need your input:**
- [Question]? (Assuming: [default])

**Constraints I'm inferring:**
- [constraint]

Ready to proceed?
```

**Wait for response before building.**

## Phase 5: Execute

Build it. Note anything unexpected for Phase 6.

## Phase 6: Handle Open Questions

For anything that emerged:
- **My gap:** What's the next step to understand?
- **Project gap:** Surface to user — "This question doesn't have an answer yet."

Create a bead if appropriate.

## Phase 7: Synthesize

```
**Implementation Complete**

Built: [what was delivered]

Decisions made:
- [choice]: [why, brief]

Open items:
- [anything unresolved]

Fragile/incomplete:
- [honest assessment]
```
