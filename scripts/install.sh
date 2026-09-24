#!/usr/bin/env bash
# Instalacja skilla w projekcie (uruchom w katalogu głównym repozytorium projektu).
# Użycie: bash install.sh [--clone]   (domyślnie git submodule)
set -euo pipefail
REPO_URL="${AI_SEC_SKILL_REPO:-git@github.com:jdanproject/ai-web-security-skill.git}"
DEST=".cursor/skills/ai-web-security"
MODE="${1:-submodule}"

mkdir -p .cursor/skills .cursor/rules
if [ -d "$DEST/.git" ] || [ -f "$DEST/.git" ]; then
  echo "Skill już zainstalowany w $DEST"
elif [ "$MODE" = "--clone" ] || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git clone --depth 50 "$REPO_URL" "$DEST"
  grep -qxF "$DEST/" .gitignore 2>/dev/null || echo "$DEST/" >> .gitignore
else
  git submodule add "$REPO_URL" "$DEST"
fi

ln -sfn "../skills/ai-web-security/.cursor/rules/ai-web-security.mdc" .cursor/rules/ai-web-security.mdc
echo "Gotowe. Reguła: .cursor/rules/ai-web-security.mdc -> $DEST"
echo "Wersja: $(cat "$DEST/VERSION")"
