# Claude Code Tools

Custom skills, hooks, and configurations for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

These tools form a **session lifecycle** for working with Claude Code on real projects. They're designed to work with [beads](https://github.com/steveyegge/beads) — a git-backed issue tracker built for coding agents — but the individual pieces are useful standalone too.

## What's Here

| Tool | Type | What it does |
| ---- | ---- | ------------ |
| [Handover](#handover) | Skill | Structured session handover to prevent context loss between conversations |
| [Ready Check](#ready-check) | Skill | Forces reflection on understanding before acting — catches mechanical pattern-matching |
| [Post-Commit Reflect](#post-commit-reflect) | Hook | Prompts Claude to reflect after each git commit, adapts behavior based on remaining context |
| [Context Status Line](#context-status-line) | Status Line | Tracks context window % remaining — displays it in the status bar and persists it to disk for the post-commit hook |

---

## The Workflow

Claude Code conversations have a hard limit: the context window. Every message, every file read, every tool call eats into it. When it runs out, the session is over and the next Claude starts completely blank.

These tools turn that constraint into a structured workflow instead of a cliff edge.

### Session Lifecycle

```text
┌─────────────────────────────────────────────────────────┐
│  SESSION START                                          │
│                                                         │
│  Claude reads CLAUDE.md (automatic)                     │
│  Tell Claude to check beads: "bd ready" or "bd list"    │
│  Claude sees what work is available                     │
│                                                         │
│  /ready-check  →  Orientation Mode                      │
│  Verifies understanding against actual code             │
│  Checks load-bearing context from previous sessions     │
│  Surfaces verification gaps                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  PICK A TASK                                            │
│                                                         │
│  Claude reads the bead for a task                       │
│  /ready-check  →  Implementation Mode (or automatic)    │
│  Traces from user goal → implementation                 │
│  Identifies unknowns, asks only what it can't decide    │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  DO THE WORK                                            │
│                                                         │
│  Status bar shows context % remaining throughout        │
│  Write code, iterate, test                              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  ~50% CONTEXT  →  COMMIT                                │
│                                                         │
│  Ask Claude to commit                                   │
│  Post-commit hook fires automatically                   │
│  Claude reflects: assumptions? fragile? do differently? │
│  If substantive → fix now (context permits)             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  SESSION END  →  /handover                              │
│                                                         │
│  Structured review of everything that happened          │
│  Updates CLAUDE.md with new critical knowledge          │
│  Creates tasks for unfinished work                      │
│  Logs fragility and shipped assumptions                 │
│                                                         │
│  Next Claude starts blank but has:                      │
│    • Updated CLAUDE.md (reads automatically)            │
│    • Tasks with full context (if using beads or similar)│
│    • Clean git history                                  │
└─────────────────────────────────────────────────────────┘
```

### Why This Matters

Without this, sessions end one of two ways: Claude hits the context wall mid-task and the conversation compacts or dies, or you start a new session and the next Claude has no idea what happened. Knowledge evaporates. Work gets repeated. Bugs get reintroduced.

This workflow makes each session self-contained: commit the work, reflect on it, hand over context, pick up cleanly next time.

---

## Skills

Skills are markdown files that define reusable prompts Claude can execute. They live in a `skills/` folder and are invoked with `/skill-name`.

### Installing Skills

**Global** (available in all projects):

```bash
cp -r skills/handover ~/.claude/skills/
cp -r skills/ready-check ~/.claude/skills/
```

**Per-project** (available only in that project):

```bash
cp -r skills/handover your-project/.claude/skills/
cp -r skills/ready-check your-project/.claude/skills/
```

After installation, invoke with `/handover` or `/ready-check` in any Claude Code session.

---

### Handover

**Path:** `skills/handover/SKILL.md`
**Invoke:** `/handover`

Structured session handover protocol. Use when ending a session to ensure the next Claude instance doesn't repeat your mistakes, miss your discoveries, or break what you fixed.

Walks through:

- What changed and how the system behaves differently
- What was learned, including dead ends
- Unfinished work, fragile code, shipped assumptions
- Artifact verification — was it tested? does it actually work?
- Produces actionable output: updates to CLAUDE.md, new beads/issues, debt log entries

The core premise: **this conversation will vanish.** Everything Claude knows that isn't written to a file is lost. This skill forces that reckoning.

---

### Ready Check

**Path:** `skills/ready-check/SKILL.md`
**Invoke:** `/ready-check`

Forces Claude to verify understanding before acting. Two modes:

**Orientation Mode** — use at session start or context switches:

- Verify project understanding against actual code
- Identify and check load-bearing context
- Surface verification gaps from previous handovers
- Survey available work

**Implementation Mode** — use before non-trivial builds:

- Traceability test: can you trace from user goal to this implementation?
- Confidence check: genuine understanding vs. pattern-matching?
- Categorize unknowns into implementation decisions (Claude decides) vs. behavior decisions (user decides)
- Checkpoint before building

Catches the failure mode where Claude says "straightforward" and then builds the wrong thing.

---

## Hooks

Hooks are scripts that run in response to Claude Code lifecycle events (e.g., after a tool is used, before compaction, at session start). They're configured in `settings.json`.

### Post-Commit Reflect

**Path:** `hooks/post-commit-reflect/post-commit-reflect.sh`
**Event:** `PostToolUse` (fires after Bash tool use)

After every `git commit`, prompts Claude to pause and reflect:

1. Assumptions left unquestioned?
1. Anything fragile or incomplete?
1. What would you do differently?

**Context-aware behavior:**

- **Above 40% context remaining** — if the reflection is substantive, fix it now (if quick) or create a task
- **Below 40% context remaining** — don't fix anything, just capture it as a task (preserves remaining context for essential work)

**Deduplication:** Won't fire more than once every 5 minutes per project, preventing repeated triggering during fix-commit cycles.

**Requires:** The [Context Status Line](#context-status-line) to be active (writes context % to `~/.claude/state/context-remaining.txt`).

### Installing the Hook

1. Copy the script and create the state directory:

```bash
cp hooks/post-commit-reflect/post-commit-reflect.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/post-commit-reflect.sh
mkdir -p ~/.claude/state
```

2. Add to your `~/.claude/settings.json` or project-level `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-commit-reflect.sh"
          }
        ]
      }
    ]
  }
}
```

**Dependencies:** `jq`, `bc`

---

## Status Line

The status line is the persistent bar at the bottom of Claude Code. You can configure it to run a command that produces the display text.

### Context Status Line

**Path:** `status-line/context-status-line.sh`

Does two things:

1. **Displays** `working-directory | Model Name | Context: 73% remaining` in the status bar
1. **Persists** the context percentage to `~/.claude/state/context-remaining.txt` on every update

That second part is critical. The [Post-Commit Reflect](#post-commit-reflect) hook reads that file to decide whether Claude should fix issues now or just capture them as tasks. Without the status line writing this file, the hook defaults to assuming 100% context remaining and will always tell Claude to fix things inline — which is exactly what you don't want when context is running low.

**If you use the post-commit hook, you need this status line active** even if you don't care about the status bar display itself.

### Installing the Status Line

**Option A — Inline** (single line in settings, no external file):

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "input=$(cat); dir=$(echo \"$input\" | jq -r '.workspace.current_dir'); model=$(echo \"$input\" | jq -r '.model.display_name'); remaining=$(echo \"$input\" | jq -r '.context_window.remaining_percentage // empty'); if [ -n \"$remaining\" ]; then mkdir -p ~/.claude/state && echo \"$remaining\" > ~/.claude/state/context-remaining.txt; printf \"%s | %s | Context: %.0f%% remaining\" \"$dir\" \"$model\" \"$remaining\"; else printf \"%s | %s\" \"$dir\" \"$model\"; fi"
  }
}
```

**Option B — External script** (cleaner, easier to edit):

```bash
cp status-line/context-status-line.sh ~/.claude/
chmod +x ~/.claude/context-status-line.sh
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/context-status-line.sh"
  }
}
```

**Dependencies:** `jq`

---

## How the Pieces Connect

**Data flow** — the status line and hook are directly connected:

```text
Status Line (runs continuously)
    │
    ├── Displays context % in the status bar
    └── Writes % to ~/.claude/state/context-remaining.txt
                                    │
                                    ▼
Post-Commit Hook (fires on git commit)
    │
    ├── Reads context % from that file
    ├── > 40%: reflect → fix now if quick
    └── < 40%: reflect → just capture as task, preserve context
```

**Workflow only** — these don't share data with the above, they're used at different points in the session:

```text
Ready Check (/ready-check)
    ├── Orientation: verify understanding, survey work
    └── Implementation: trace goals, identify unknowns, checkpoint

Handover (/handover)
    ├── Reviews everything that happened
    ├── Updates CLAUDE.md
    └── Creates tasks for unfinished work
```

All four tools are independent — use any combination. But together they cover the full session lifecycle: orient, work, reflect, hand over.

---

## Beads

These tools are designed to pair with [beads](https://github.com/steveyegge/beads), Steve Yegge's git-backed issue tracker for coding agents. Beads gives Claude persistent memory across sessions — tasks, context, dependencies — stored right in your git repo.

The **status line** and **post-commit hook** work fine without beads — they only depend on each other. The **ready-check** skill references beads commands but degrades gracefully without them.

The **handover** skill references beads throughout (`bd ready`, `bd sync`, "create beads for unfinished work"). Without beads installed, Claude will still run the handover review and update CLAUDE.md, but the task-creation and sync parts won't do anything. If you're not using beads, you'd want to adapt those sections to whatever task tracking you do use.

---

## License

MIT
