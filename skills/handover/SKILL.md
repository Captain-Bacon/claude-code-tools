---
name: handover
description: Session review and context handover for the next Claude. Use when ending a session to ensure knowledge transfer and prevent context loss.
user-invocable: true
---

# Session Handover

**This conversation will vanish.** Everything you know that isn't written to a file will be lost.

The next Claude starts blank. They only see:
- CLAUDE.md (read automatically)
- Beads (only if they query them)
- Code (only if they navigate there)

Your job: ensure they don't repeat your mistakes, miss your discoveries, or break what you fixed.

---

## Persistence Hierarchy

| Storage | When it surfaces | Use for |
|---------|------------------|---------|
| **CLAUDE.md** | Before ANY work | Critical knowledge, gotchas, warnings, system truths |
| **Beads** | Only when queried (`bd ready`, `bd list`) | Work items. NOT knowledge transfer. |
| **Code comments** | Only if already in that file | Documentation for that location only |
| **Conversation** | **NEVER** | Nothing. It vanishes. |

**CLAUDE.md is the only reliable handover** — the only thing next Claude definitely sees before working.

**Beads are for work, not knowledge.** A bead saying "don't use old API param" is useless if next Claude doesn't check beads before modifying that module. If they need to know something BEFORE breaking it → CLAUDE.md.

**However:** Beads ARE good for session context and notes precisely because they're queryable. Task-specific context goes on tasks.

---

## The Review

Work through these — don't skim, actually answer:

**What changed?**
- How does the system behave differently now?
- Walk through CLAUDE.md — what's outdated or incomplete?
- What would mislead next Claude if left as-is?

**What did I learn?**
- What surprised you or didn't work as expected?
- What rabbit holes led nowhere? Why?
- Message to yourself at session start — what would it say?

**What's unfinished?**
- Every TODO, FIXME, placeholder in code
- What you told user you'd do but haven't
- Where you stopped short of "properly done"

**What's fragile?**

Complete these:
- "This works now, but only because..."
- "If someone changes X without knowing about Y, then..."
- What assumptions won't next Claude know to make?

| Fragility | Why fragile | Robust alternative |
|-----------|-------------|-------------------|
| [what] | [what breaks] | [what robust looks like] |

**What assumptions did I ship?**

| Assumption | Status | Action if unverified |
|------------|--------|---------------------|
| [what you assumed] | Verified / Beaded / Shipped as guess | [if guess: why acceptable, OR bead now] |

Every assumption gets one of: verified, beaded, or justified as acceptable guess.

---

## Artifact Verification Gate (CRITICAL)

**For every artifact created this session, explicitly state verification status:**

| Artifact | Type | Verified? | If Yes: Result | If No: Why |
|----------|------|-----------|----------------|------------|
| [script/feature/fix] | Script/Feature/Fix | Yes/No | [what you tested, what happened] | [untested / blocked by X / out of scope] |

**Why this matters:** Next Claude sees "script exists" but not "script works." Without explicit verification status, they'll either:
- Assume it works (and waste time debugging)
- Assume it doesn't (and waste time re-verifying)

**For spawned agents:**

| Agent | Purpose | Insights Captured? | Where |
|-------|---------|-------------------|-------|
| [agent ID] | [what it did] | Yes/No/Partial | [handover doc / bead / lost] |

Agent temp output files vanish between sessions. Capture insights in persistent storage or mark as lost.

**For open issues affecting current work:**

| Issue | Affects | Blocking? | Call |
|-------|---------|-----------|------|
| [bead ID] | [what it impacts] | Yes/No | [if yes: what's blocked. if no: workaround/noise] |

Don't leave blockers as ambiguous. Make the judgment call and document it.

---

## Reflection → Action

**Reflection without action is wasted.** Next Claude can't see your thoughts.

| Found | Action |
|-------|--------|
| Unfinished work | Bead describing what remains and why |
| Fragile code | Fix now if quick, OR bead with full context |
| Technical debt | Bead explaining debt and resolution |
| Undocumented gotcha | CLAUDE.md if critical, OR bead |

**The rule:** For every item surfaced:
1. **Fix now** — if quick and you have context
2. **Create bead** — if needs future work
3. **Update CLAUDE.md** — if critical knowledge
4. **Log to debt-log** — if accepting fragility (see below)
5. **Intentionally discard** — if truly not worth tracking

---

## Debt Log

When accepting fragility or shipping a guess, log to `.claude/debt-log.md`:

```markdown
| Date | Area | What | Why accepted | Robust alternative |
|------|------|------|--------------|-------------------|
| 2026-02-01 | VisionService | String matching errors | Low risk | Structured error protocol |
```

**If same area has 3+ entries** → create investigation bead:
- Title: "Investigate accumulated debt in [Area]"
- Fresh Claude reviews whether area needs redesign

---

## Where Things Go

### → CLAUDE.md
Next Claude needs this BEFORE touching code:
- System truths ("API uses X param, not Y like docs say")
- Critical warnings
- Gotchas causing silent failure
- Couplings ("change X → must update Y")

### → Bead (work item)
Work to track. **Must be self-contained:**
- What the task actually is
- Why it matters
- Where you stopped
- Approach you were taking
- Gotchas discovered

Next Claude should start without asking "what does this mean?"

### → Bead (session handover)
General session context not tied to specific task:
- Title: "SESSION HANDOVER: [date]"
- Priority: P0 (appears first in `bd ready`)
- Close once read

Content: what session worked on, key decisions, docs to read, what's unfinished.

### → Bead (task notes)
Context specific to ONE task: `bd update <id> --notes="..."`
- Progress on that task
- Approach taken
- Task-specific gotchas

### → Code
Documentation for that specific location only.

### → Nowhere
Session noise. Intentional, not neglect:
- Debugging steps tried
- Transient issues that resolved
- Things next Claude can rediscover easily

---

## Checklist

```
[ ] CLAUDE.md reviewed — still accurate?
[ ] CLAUDE.md updated — new critical knowledge?
[ ] Beads created — work to track?
[ ] Every fragile/unfinished item actioned — fixed or beaded?
[ ] Artifact verification gate complete — tested/untested explicit?
[ ] Agent insights captured — not relying on temp files?
[ ] Blocker status explicit — blocking or noise?
[ ] Session handover bead — if next Claude needs general context?
[ ] Task notes added — context on specific tasks?
[ ] Code TODOs logged — bead for each TODO added?
[ ] Beads synced — run `bd sync`
```

**TODO trap:** TODO in code without a bead will never surface.
**Reflection trap:** "This is fragile" without a bead = wasted reflection.
**Verification trap:** "Created X" without "tested: yes/no" = ambiguity for next Claude.

---

## Verification

> "If new Claude read CLAUDE.md, ran `bd ready`, and `bd show` on top task — would they have everything to continue without breaking anything or repeating my mistakes?"

**Yes** → Done.
**No** → What's missing? Where should it go?
