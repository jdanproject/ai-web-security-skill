# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).
- MAJOR – skill structure change or a new standard edition that changes risk IDs
- MINOR – new rules, sections, sources
- PATCH – fixes, clarifications, link updates

## [1.1.0] – 2026-09-24
### Changed
- Entire skill translated to English (more token-efficient context for AI agents). Rules unchanged.
- Install URLs switched to HTTPS (public repository); license note CC BY-SA 4.0.

## [1.0.0] – 2026-09-24
### Added
- `SKILL.md` with mandatory rules based on OWASP Top 10 for LLM Applications 2026 (LLM01–LLM10) and OWASP Agentic Top 10 2026 (ASI01–ASI10).
- References: web chat, agents/tools/MCP, RAG/vectors, web hardening, Perl/Node.js/PostgreSQL/MariaDB/Apache patterns, testing and red teaming, review checklist.
- Cursor rule `.cursor/rules/ai-web-security.mdc` and install script.
- `SOURCES.md` and `sources.json` for source change tracking.
