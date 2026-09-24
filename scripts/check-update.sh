#!/usr/bin/env bash
# Checks for and pulls skill updates (fast-forward). By default at most once every 7 days.
# Usage: bash check-update.sh [--force]
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$DIR/.git-last-check"
[ -f "$DIR/.git" ] && STAMP="$DIR/../.ai-web-security-last-check"
INTERVAL=$((7*24*3600))
now=$(date +%s)

if [ "${1:-}" != "--force" ] && [ -f "$STAMP" ]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  if [ $((now-last)) -lt $INTERVAL ]; then
    echo "ai-web-security $(cat "$DIR/VERSION") – checked recently, skipping (use --force)."
    exit 0
  fi
fi

old=$(cat "$DIR/VERSION")
git -C "$DIR" fetch --quiet --tags origin
behind=$(git -C "$DIR" rev-list --count HEAD..origin/main)
echo "$now" > "$STAMP"

if [ "$behind" -eq 0 ]; then
  echo "ai-web-security $old – up to date."
  exit 0
fi

git -C "$DIR" pull --quiet --ff-only origin main
new=$(cat "$DIR/VERSION")
echo "ai-web-security updated: $old -> $new ($behind commit(s))."
echo "--- New CHANGELOG.md entries ---"
awk -v old="$old" '/^## \[/{ if (index($0,"["old"]")) exit } f||/^## \[/{f=1; print}' "$DIR/CHANGELOG.md"
echo "Note: if the skill is a submodule, commit the new pointer: git add .cursor/skills/ai-web-security && git commit -m 'Update ai-web-security skill'"
