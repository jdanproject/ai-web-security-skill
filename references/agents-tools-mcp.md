# Agents, Tools and MCP

## OWASP Top 10 for Agentic Applications 2026

| ID | Risk | Key control |
|---|---|---|
| ASI01 | Agent Goal Hijack – goals redirected by injected instructions or poisoned content | Separate data from instructions, verify plan before sensitive actions |
| ASI02 | Tool Misuse and Exploitation – abuse of legitimate tools | Narrow tools, schemas, per-call policies |
| ASI03 | Identity and Privilege Abuse | Act in user context, short-lived credentials, no "super-agent" accounts |
| ASI04 | Agentic Supply Chain Vulnerabilities | Vet MCP servers, skills, plugins; pin versions |
| ASI05 | Unexpected Code Execution (RCE) | No `eval`/shell; if code is required – isolated sandbox without network |
| ASI06 | Memory and Context Poisoning | Validate memory writes, per-user isolation, ability to purge |
| ASI07 | Insecure Inter-Agent Communication | Authenticated channels; messages from other agents = untrusted data |
| ASI08 | Cascading Failures | Step limits, circuit breakers, fault isolation |
| ASI09 | Human-Agent Trust Exploitation | Confirmations showing raw operations, no persuasive summaries |
| ASI10 | Rogue Agents | Behavior monitoring, kill switch, audit |

## Tool design (function calling)

1. **Inventory**: every tool, its permissions and credentials, owner.
2. **Minimalism**: only tools required for the task. An informational chatbot needs no write tools.
3. **Narrow operations**: `get_order_status(order_id)` instead of `run_sql(query)`; `send_reset_link()` instead of `send_email(to, body)`.
4. **Strict schema**: JSON Schema with `additionalProperties: false`, types, ranges, patterns, enums. Validate **server-side** (ajv / JSON::Validator) – the model may ignore the schema.
5. **User context**: the tool executor injects `user_id`/`tenant_id` from the session. Ownership parameters never come from the model.
6. **Pre-execution policy**: a deterministic rules engine checks (who, what, on which resource, how often) at execution time.
7. **Risk tiers**:
   - reading own data → automatic,
   - reversible write → automatic with log and limit,
   - irreversible / financial / external communication → human confirmation with raw parameter preview.
8. **Tool results** return to the model as untrusted data (they may contain injection, e.g. email body, web page).
9. **Limits**: max calls per turn and per session, loop detection (repeated identical calls), timeouts.

## The "lethal trifecta"

The most dangerous combination in a single agent:
1. access to private data,
2. exposure to untrusted content,
3. ability to communicate externally (HTTP, email, images in output).

If an agent has all three – **remove at least one leg** (e.g. no network egress, no image rendering, split into two agents with different permissions) or require confirmation for every external communication.

## Architectural patterns

- **Dual LLM / quarantined LLM**: the privileged model (with tools) never sees raw untrusted content; the quarantined model processes content and returns strictly structured output (enums, numbers), no free text.
- **Plan-then-execute**: the action plan is fixed before touching untrusted data; data cannot add new actions.
- **Egress allowlist**: tool sandbox with network egress only to specific domains (filtering proxy).

## MCP (Model Context Protocol)

### MCP server (if you build one)
- HTTP transport: OAuth 2.1 per the MCP Authorization spec; the server is a resource server and validates the token `aud` – **reject tokens issued for other resources** (no token passthrough).
- Narrow scopes, separate credentials per server, short TTLs.
- Validate every tool's input as you would a public API.
- Tool descriptions are static and reviewed – descriptions are part of the model prompt.
- Local transport (stdio): run with minimal OS privileges; never listen on `0.0.0.0` without authentication; protect against DNS rebinding (validate `Origin`/`Host`).
- Sessions: random IDs not tied to authorization; verify authorization on every request.

### MCP client / host (if you connect third-party servers)
- Only servers from trusted sources, pinned versions, reviewed code and tool descriptions.
- Protect against **tool poisoning** (hidden instructions in tool descriptions) and **rug pulls** (descriptions changed after approval) – hash descriptions, alert on change.
- Protect against **tool shadowing** – unique tool namespaces per server.
- User confirmation for write tools; show full arguments.
- Isolation: each server in its own container/user, egress through a filtering proxy.
- Confused deputy with OAuth proxies: per-client user consent, validate `redirect_uri`.

## Agent memory

- Memory writes only from trusted paths or after validation; tag the source of every entry.
- Per-user/tenant isolation; no shared memory across customers.
- Users can view and delete their memory.
- TTL on entries, periodic anomaly review.

## Multi-agent systems

- Inter-agent messages are authenticated (signature/mTLS) and treated as untrusted data.
- An agent does not automatically inherit the calling agent's permissions.
- Limits on recursion and delegation depth.
