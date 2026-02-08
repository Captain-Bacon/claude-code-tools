#!/bin/bash

# Claude Code Status Line: Context Window Tracker
#
# Displays: working directory | model name | context % remaining
# Also persists context % to ~/.claude/state/context-remaining.txt
# so other tools (like post-commit-reflect) can read it.
#
# This script is meant to be used as the "command" value in your
# statusLine settings config. See README for installation.

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

if [ -n "$remaining" ]; then
  mkdir -p ~/.claude/state
  echo "$remaining" > ~/.claude/state/context-remaining.txt
  printf "%s | %s | Context: %.0f%% remaining" "$dir" "$model" "$remaining"
else
  printf "%s | %s" "$dir" "$model"
fi
