# RAG, Embeddings and Vector Stores

## Document ingestion

- Extract text in an isolated process (PDF/DOCX/HTML parsers are complex – RCE/DoS risk); size and time limits.
- Normalize before embedding: strip zero-width chars, Unicode tags, homoglyphs, hidden text (white-on-white, `display:none`, zero font size, HTML comments, metadata).
- Provenance for every chunk: `source_id`, `source_url`, `ingested_at`, `trust_tier`, `pipeline_version`, `owner_tenant`, `acl`.
- User-generated content (reviews, tickets, uploads) → separate low-trust index; review before it reaches the knowledge index.
- Web content → never in the same index as internal documents without hard isolation.

## Access control

- **Permission filter inside the query**, server-side, derived from the session:

```sql
-- PostgreSQL + pgvector
SELECT id, content, source_url
FROM kb_chunks
WHERE tenant_id = $1               -- from session, not from client request
  AND acl && $2::text[]            -- user roles from session
ORDER BY embedding <=> $3
LIMIT 8;
```

- Enable PostgreSQL Row Level Security on chunk tables as a second line of defense:

```sql
ALTER TABLE kb_chunks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON kb_chunks
  USING (tenant_id = current_setting('app.tenant_id')::bigint);
```

- Chunk-level ACLs – a public document can contain a confidential paragraph.
- Embedding and search endpoints are APIs: authentication, per-tenant limits.
- Never return raw similarity scores or vectors to clients (embedding inversion risk).

## At answer time

- Pass chunks to the model in an `untrusted_data` block with source attribution.
- Show sources (citations) to the user – helps verification and poisoning detection.
- Cap the number and total length of chunks.

## Poisoning detection

- Alert when a new vector is very close to many common queries (retrieval hijacking).
- Monitor chunks with imperative phrases aimed at AI ("ignore previous", "as an AI assistant you must", "system:"), including other languages and base64.
- Ability to invalidate an entire batch by `pipeline_version`/`source_id`.

## Lifecycle

- Source document deleted → embeddings deleted within a bounded time; periodic reconciliation.
- Embeddings of personal data are subject to GDPR (right to erasure).
- Index backups carry the same classification as the source data.
