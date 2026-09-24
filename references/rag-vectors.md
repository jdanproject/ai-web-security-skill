# RAG, embeddingi i bazy wektorowe

## Ingest dokumentów

- Ekstrakcja tekstu w izolowanym procesie (PDF/DOCX/HTML to złożone parsery – ryzyko RCE/DoS); limity rozmiaru i czasu.
- Normalizacja przed embeddingiem: usuń zero-width, tagi Unicode, homoglify, ukryty tekst (biały na białym, `display:none`, font 0, komentarze HTML, metadane).
- Proweniencja każdego fragmentu: `source_id`, `source_url`, `ingested_at`, `trust_tier`, `pipeline_version`, `owner_tenant`, `acl`.
- Treści od użytkowników (recenzje, zgłoszenia, uploady) → osobny indeks o niskim zaufaniu; przegląd przed trafieniem do indeksu wiedzy.
- Treści z internetu → nigdy w jednym indeksie z dokumentami wewnętrznymi bez twardej izolacji.

## Kontrola dostępu

- **Filtr uprawnień wewnątrz zapytania**, po stronie serwera, na podstawie sesji:

```sql
-- PostgreSQL + pgvector
SELECT id, content, source_url
FROM kb_chunks
WHERE tenant_id = $1               -- z sesji, nie z żądania klienta
  AND acl && $2::text[]            -- role użytkownika z sesji
ORDER BY embedding <=> $3
LIMIT 8;
```

- Włącz Row Level Security w PostgreSQL dla tabel z fragmentami jako drugą linię obrony:

```sql
ALTER TABLE kb_chunks ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON kb_chunks
  USING (tenant_id = current_setting('app.tenant_id')::bigint);
```

- ACL na poziomie fragmentu – dokument publiczny może zawierać poufny akapit.
- Endpointy embeddingu i wyszukiwania są API: uwierzytelnienie, limity per tenant.
- Nie zwracaj klientowi surowych wyników podobieństwa ani wektorów (ryzyko inwersji embeddingów).

## Przy odpowiedzi

- Fragmenty przekazywane do modelu w bloku `untrusted_data` z oznaczeniem źródła.
- Pokazuj użytkownikowi źródła (cytaty) – ułatwia weryfikację i wykrywanie zatrucia.
- Ogranicz liczbę i łączną długość fragmentów.

## Wykrywanie zatrucia

- Alarmuj, gdy nowy wektor jest bardzo bliski wielu typowym zapytaniom (retrieval hijacking).
- Monitoruj fragmenty zawierające frazy imperatywne skierowane do AI („ignore previous”, „as an AI assistant you must”, „system:”), także w innych językach i base64.
- Możliwość unieważnienia całej partii po `pipeline_version`/`source_id`.

## Cykl życia

- Usunięcie dokumentu źródłowego → usunięcie embeddingów w określonym czasie; okresowa rekonsyliacja.
- Embeddingi danych osobowych podlegają RODO (prawo do usunięcia).
- Kopie zapasowe indeksu z tą samą klasyfikacją co dane źródłowe.
