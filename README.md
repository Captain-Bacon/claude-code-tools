# Claude Code Tools

Custom skills, hooks, and configurations for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## What's Here

| Tool | Type | What it does |
|------|------|-------------|
| [Handover](#handover) | Skill | Structured session handover to prevent context loss between conversations |
| [Ready Check](#ready-check) | Skill | Forces reflection on understanding before acting — catches mechanical pattern-matching |
| [Post-Commit Reflect](#post-commit-reflect) | Hook | Prompts Claude to reflect after each git commit, adapts behavior based on remaining context |
| [Context Status Line](#context-status-line) | Status Line | Shows model, directory, and context window % remaining in the status bar |

---

## Skills

Skills are markdown files that define reusable prompts Claude can execute. They live in a `skills/` folder and are invoked with `/skill-name`.

### Installation

**Global** (available in all projects):

```bash
# Copy the skill folder into your global skills directory
cp -r skills/handover ~/.claude/skills/
cp -r skills/ready-check ~/.claude/skills/
```

**Per-project** (available only in that project):

```bash
# Copy into the project's .claude directory
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
- Artifact verification (was it tested? does it work?)
- Produces actionable output: updates to CLAUDE.md, new issues/tasks, debt log entries

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
2. Anything fragile or incomplete?
3. What would you do differently?

**Context-aware behavior:**
- **Above 40% context remaining** — if the reflection is substantive, fix it now (if quick) or create a task
- **Below 40% context remaining** — don't fix anything, just capture it as a task (preserves remaining context for essential work)

**Deduplication:** Won't fire more than once every 5 minutes per project, preventing repeated triggering during fix-commit cycles.

**Requires:** The [Context Status Line](#context-status-line) to be active (writes context % to `~/.claude/state/context-remaining.txt`).

### Installation

1. Copy the script:

```bash
cp hooks/post-commit-reflect/post-commit-reflect.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/post-commit-reflect.sh
```

2. Create the state directory:

```bash
mkdir -p ~/.claude/state
```

3. Add to your `~/.claude/settings.json` (or project-level `.claude/settings.json`):

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

Displays: `working-directory | Model Name | Context: 73% remaining`

Also persists the context percentage to `~/.claude/state/context-remaining.txt`, which other tools (like [Post-Commit Reflect](#post-commit-reflect)) can read.

### Installation

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

1. Copy the script:

```bash
cp status-line/context-status-line.sh ~/.claude/
chmod +x ~/.claude/context-status-line.sh
```

2. Add to `~/.claude/settings.json`:

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

## How These Work Together

The status line and post-commit hook are designed as a pair:

```
Status Line (runs continuously)
    │
    ├── Displays context % in status bar
    └── Writes context % to ~/.claude/state/context-remaining.txt
                                    │
Post-Commit Hook (runs after git commit)
    │
    ├── Reads context % from that file
    ├── If > 40%: reflect and fix now
    └── If < 40%: reflect but just capture, don't burn context
```

The skills (handover, ready-check) are standalone — use them independently or together.

---

## License

MIT
