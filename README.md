# ai-web-security-skill

A skill (guidelines for AI coding agents) covering the security of AI features in web applications: chatbots, support assistants, RAG, tool-using agents and MCP servers.

Based on **OWASP Top 10 for LLM Applications 2026** and **OWASP Top 10 for Agentic Applications 2026**, with code patterns for Perl, Node.js, PostgreSQL, MariaDB and Apache.

The repository is updated monthly: sources listed in `sources.json` are compared against the skill, and changes land on `main` with a `CHANGELOG.md` entry and a version tag.

## Layout

```
SKILL.md                     main guidelines (Agent Skills format)
references/                  detailed material and checklists
.cursor/rules/*.mdc          Cursor AI rule
scripts/install.sh           install into a project
scripts/check-update.sh      check for and pull updates
SOURCES.md, sources.json     tracked sources and their state
CHANGELOG.md, VERSION        change history and current version
```

## Install into a project (Cursor)

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/jdanproject/ai-web-security-skill/main/scripts/install.sh | bash
# or manually:
git submodule add https://github.com/jdanproject/ai-web-security-skill.git .cursor/skills/ai-web-security
ln -sfn ../skills/ai-web-security/.cursor/rules/ai-web-security.mdc .cursor/rules/ai-web-security.mdc
```

The non-submodule variant (`install.sh --clone`) clones the repository and adds the directory to `.gitignore`.

Result:
- `.cursor/skills/ai-web-security/` – the skill (Cursor versions supporting Agent Skills discover it automatically),
- `.cursor/rules/ai-web-security.mdc` – a rule the agent attaches when working on AI features (or invoke manually with `@ai-web-security`).

## Updates

Per the rule, the Cursor agent runs before working on an AI feature:

```bash
bash .cursor/skills/ai-web-security/scripts/check-update.sh          # at most once every 7 days
bash .cursor/skills/ai-web-security/scripts/check-update.sh --force  # immediately
```

The script runs `git fetch` and `git pull --ff-only`, then prints new changelog entries. For a submodule, commit the new pointer in the project repository.

Manually: `git -C .cursor/skills/ai-web-security pull --ff-only`.

Pin a version: `git -C .cursor/skills/ai-web-security checkout v1.1.0`.

## Other agents

- Claude Code: copy/symlink the directory to `.claude/skills/ai-web-security/`.
- Codex CLI / others: reference `SKILL.md` from the project's `AGENTS.md`.

## License

CC BY-SA 4.0 (consistent with the license of the OWASP source material).
