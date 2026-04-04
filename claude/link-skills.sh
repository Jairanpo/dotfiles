#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

linked=0
skipped=0

for skill_path in "$SCRIPT_DIR"/*/; do
  skill_name="$(basename "$skill_path")"
  link_path="$SKILLS_DIR/$skill_name"

  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    echo "skip: $skill_name (already exists at $link_path)"
    ((skipped++))
    continue
  fi

  ln -s "$skill_path" "$link_path"
  echo "linked: $skill_name → $link_path"
  ((linked++))
done

echo ""
echo "done: $linked linked, $skipped skipped"
