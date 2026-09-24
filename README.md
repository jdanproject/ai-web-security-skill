# ai-web-security-skill

Skill (wytyczne dla agentów AI) dotyczący bezpieczeństwa funkcji AI w aplikacjach WWW: czatów, asystentów wsparcia, RAG, agentów z narzędziami i serwerów MCP.

Oparty na **OWASP Top 10 for LLM Applications 2026** i **OWASP Top 10 for Agentic Applications 2026**, z wzorcami kodu dla Perl, Node.js, PostgreSQL, MariaDB i Apache.

Repozytorium jest aktualizowane cyklicznie (co miesiąc): źródła z `sources.json` są porównywane ze stanem skilla, a zmiany trafiają na `main` z wpisem w `CHANGELOG.md` i tagiem wersji.

## Struktura

```
SKILL.md                     główne wytyczne (format Agent Skills)
references/                  szczegółowe materiały i checklisty
.cursor/rules/*.mdc          reguła dla Cursor AI
scripts/install.sh           instalacja w projekcie
scripts/check-update.sh      sprawdzanie i pobieranie aktualizacji
SOURCES.md, sources.json     monitorowane źródła i ich stan
CHANGELOG.md, VERSION        historia zmian i bieżąca wersja
```

## Instalacja w projekcie (Cursor)

W katalogu głównym projektu:

```bash
curl -fsSL https://raw.githubusercontent.com/jdanproject/ai-web-security-skill/main/scripts/install.sh | bash
# lub ręcznie:
git submodule add https://github.com/jdanproject/ai-web-security-skill.git .cursor/skills/ai-web-security
ln -sfn ../skills/ai-web-security/.cursor/rules/ai-web-security.mdc .cursor/rules/ai-web-security.mdc
```

Wariant bez submodułu (`install.sh --clone`) klonuje repozytorium i dodaje katalog do `.gitignore`.

Efekt:
- `.cursor/skills/ai-web-security/` – skill (wersje Cursora obsługujące Agent Skills wykrywają go automatycznie),
- `.cursor/rules/ai-web-security.mdc` – reguła, którą agent dołącza przy pracy nad funkcjami AI (można też wywołać ręcznie przez `@ai-web-security`).

## Aktualizacje

Agent w Cursorze uruchamia (zgodnie z regułą) przed pracą nad funkcją AI:

```bash
bash .cursor/skills/ai-web-security/scripts/check-update.sh          # najwyżej raz na 7 dni
bash .cursor/skills/ai-web-security/scripts/check-update.sh --force  # natychmiast
```

Skrypt wykonuje `git fetch` i `git pull --ff-only`, a po aktualizacji wypisuje nowe wpisy z changeloga. Dla submodułu pamiętaj o zatwierdzeniu nowego wskaźnika w repozytorium projektu.

Ręcznie: `git -C .cursor/skills/ai-web-security pull --ff-only`.

Konkretna wersja: `git -C .cursor/skills/ai-web-security checkout v1.0.0`.

## Użycie z innymi agentami

- Claude Code: skopiuj/podlinkuj katalog do `.claude/skills/ai-web-security/`.
- Codex CLI / inne: wskaż `SKILL.md` w `AGENTS.md` projektu.

## Licencja

CC BY-SA 4.0 (zgodnie z licencją materiałów źródłowych OWASP).
