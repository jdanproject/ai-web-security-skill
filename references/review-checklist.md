# AI Feature Review Checklist

Legend: [ ] to check · [x] pass · [–] n/a · [!] gap

## Architecture
- [ ] Model calls only from the backend; API key only on the server
- [ ] Trust boundaries and model input sources documented
- [ ] Inventory of tools, MCP servers, credentials and providers (AIBOM)
- [ ] No agent combines private data + untrusted content + external communication (or confirmation is required)

## Input and context (LLM01, LLM08)
- [ ] Static system prompt, no interpolation of user/RAG data
- [ ] No secrets, credentials or authorization rules in context
- [ ] Untrusted content in a delimited data block
- [ ] Unicode and control-character normalization, length limit
- [ ] Conversation history server-side; client cannot modify it

## Authorization and tools (LLM03, ASI02, ASI03, ASI05)
- [ ] Authorization in code, in the authenticated user's context
- [ ] `user_id`/`tenant_id` from session, not from model arguments
- [ ] No open-ended tools (shell, arbitrary SQL/URL/file, eval)
- [ ] JSON Schema with `additionalProperties: false`, validated server-side
- [ ] Least-privilege DB/API permissions for tools
- [ ] Human confirmation for irreversible actions, showing raw parameters
- [ ] Limits on steps and tool calls, loop detection

## Output (LLM10)
- [ ] No `innerHTML`/`<%==`/`v-html`/`dangerouslySetInnerHTML` with raw output
- [ ] Markdown through an allowlist sanitizer; links only `https:`/`mailto:`
- [ ] Images from output not auto-loaded (or allowlist/proxy)
- [ ] Sanitization on the assembled stream, not per chunk
- [ ] Model output never to shell/eval; to SQL only parameterized
- [ ] CSP with restricted `img-src` and `connect-src`

## Data (LLM02, LLM09)
- [ ] Authorize before retrieval (tools, RAG)
- [ ] Tenant filter inside the vector query + RLS
- [ ] Indexes separated by trust level
- [ ] Minimization/masking of PII sent to the provider
- [ ] Provider settings: no training on data, retention, DPA, region
- [ ] Embeddings deleted when source is deleted

## Cost and availability (LLM06)
- [ ] Rate limit per user/IP; token limits
- [ ] Hard spend cap (application + provider dashboard)
- [ ] `max_tokens`, timeouts, upstream abort on client disconnect
- [ ] Bot protection for public chatbot

## Supply chain (LLM04, LLM05, ASI04)
- [ ] Pinned SDK/model/MCP server versions; review before upgrades
- [ ] Hashes of MCP tool descriptions, alert on change
- [ ] Safe model formats (no pickle)

## Misinformation and UX (LLM07, ASI09)
- [ ] Business facts (prices, statuses, policies) from the system, not the model
- [ ] Notice that the user is talking to AI
- [ ] Sources/citations for RAG answers

## Web
- [ ] Sessions: `Secure; HttpOnly; SameSite`; CSRF for state-changing requests
- [ ] CORS allowlist; WebSocket `Origin` check
- [ ] Errors without stack traces or model context
- [ ] Secrets outside the repository; gitleaks scan

## Observability and response
- [ ] Audit of tool calls and policy decisions
- [ ] Cost and injection-attempt alerts
- [ ] AI feature kill switch and incident procedure
- [ ] Security regression tests (`testing-redteam.md`) in CI
