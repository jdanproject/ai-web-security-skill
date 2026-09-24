#!/usr/bin/env bash
# Sprawdza i pobiera aktualizacje skilla (fast-forward). Domyślnie najwyżej raz na 7 dni.
# Użycie: bash check-update.sh [--force]
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$DIR/.git-last-check"
[ -f "$DIR/.git" ] && STAMP="$DIR/../.ai-web-security-last-check"
INTERVAL=$((7*24*3600))
now=$(date +%s)

if [ "${1:-}" != "--force" ] && [ -f "$STAMP" ]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  if [ $((now-last)) -lt $INTERVAL ]; then
    echo "ai-web-security $(cat "$DIR/VERSION") – sprawdzano niedawno, pomijam (użyj --force)."
    exit 0
  fi
fi

old=$(cat "$DIR/VERSION")
git -C "$DIR" fetch --quiet --tags origin
behind=$(git -C "$DIR" rev-list --count HEAD..origin/main)
echo "$now" > "$STAMP"

if [ "$behind" -eq 0 ]; then
  echo "ai-web-security $old – aktualna."
  exit 0
fi

git -C "$DIR" pull --quiet --ff-only origin main
new=$(cat "$DIR/VERSION")
echo "ai-web-security zaktualizowana: $old -> $new ($behind commit(ów))."
echo "--- Nowe wpisy w CHANGELOG.md ---"
awk -v old="$old" '/^## \[/{ if (index($0,"["old"]")) exit } f||/^## \[/{f=1; print}' "$DIR/CHANGELOG.md"
echo "Uwaga: jeśli skill jest submodułem, zatwierdź nowy wskaźnik: git add .cursor/skills/ai-web-security && git commit -m 'Update ai-web-security skill'"
