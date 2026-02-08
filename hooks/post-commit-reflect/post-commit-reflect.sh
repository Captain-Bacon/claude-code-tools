#!/bin/bash

# Read hook input from stdin
input=$(cat)

# Only trigger on git commit
command=$(echo "$input" | jq -r '.tool_input.command // empty')
if ! echo "$command" | grep -q "git commit"; then
  exit 0
fi

# Skip if fired within last 5 minutes (prevents repeated firing on fix-commit cycles)
# Use project-specific state file to avoid collision across workspaces
PROJECT_HASH=$(echo "${CLAUDE_PROJECT_DIR:-unknown}" | md5 -q 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-unknown}" | md5sum | cut -d' ' -f1)
LAST_FIRE="$HOME/.claude/state/last-commit-reflect-$PROJECT_HASH"
NOW=$(date +%s)
if [ -f "$LAST_FIRE" ]; then
  LAST=$(cat "$LAST_FIRE")
  DIFF=$((NOW - LAST))
  if [ "$DIFF" -lt 300 ]; then
    exit 0
  fi
fi
echo "$NOW" > "$LAST_FIRE"

# Read context remaining (default 100 if file doesn't exist)
REMAINING=$(cat ~/.claude/state/context-remaining.txt 2>/dev/null || echo "100")

# Build reflection prompt based on context level
if (( $(echo "$REMAINING < 40" | bc -l) )); then
  PROMPT="CONTEXT LOW (${REMAINING}%). Reflect on this commit's session:

1. Assumptions unquestioned?
2. Fragile or incomplete?
3. Do differently?

If substantive: create a task/issue with full context. Don't fix now.
If nothing: reply 'Reflection: none'.
Respond in Minimal format."
else
  PROMPT="Reflect on this commit's session:

1. Assumptions unquestioned?
2. Fragile?
3. Do differently?

If substantive: fix now if quick, else create a task/issue.
If nothing: reply 'Reflection: none'.
Respond in Minimal format."
fi

# Escape for JSON
ESCAPED_PROMPT=$(echo "$PROMPT" | jq -Rs '.')

cat <<ENDJSON
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $ESCAPED_PROMPT
  }
}
ENDJSON

exit 0
