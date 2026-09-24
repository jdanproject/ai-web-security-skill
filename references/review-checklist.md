# Checklista przeglądu funkcji AI

Oznaczenia: [ ] do sprawdzenia · [x] spełnione · [–] nie dotyczy · [!] luka

## Architektura
- [ ] Wywołania modelu wyłącznie z backendu; klucz API tylko na serwerze
- [ ] Opisane granice zaufania i źródła danych trafiających do modelu
- [ ] Inwentarz narzędzi, serwerów MCP, poświadczeń i dostawców (AIBOM)
- [ ] Agent nie łączy jednocześnie: danych prywatnych + niezaufanych treści + komunikacji zewnętrznej (lub jest potwierdzenie)

## Wejście i kontekst (LLM01, LLM08)
- [ ] System prompt statyczny, bez interpolacji danych użytkownika/RAG
- [ ] Brak sekretów, poświadczeń i reguł autoryzacji w kontekście
- [ ] Treści niezaufane w oznaczonym bloku danych
- [ ] Normalizacja Unicode i znaków sterujących, limit długości
- [ ] Historia rozmowy po stronie serwera, klient nie może jej modyfikować

## Autoryzacja i narzędzia (LLM03, ASI02, ASI03, ASI05)
- [ ] Autoryzacja w kodzie, w kontekście zalogowanego użytkownika
- [ ] `user_id`/`tenant_id` z sesji, nie z argumentów modelu
- [ ] Brak narzędzi otwartych (shell, dowolne SQL/URL/plik, eval)
- [ ] JSON Schema z `additionalProperties: false`, walidacja po stronie serwera
- [ ] Minimalne uprawnienia DB/API dla narzędzi
- [ ] Potwierdzenie człowieka dla akcji nieodwracalnych, z surowymi parametrami
- [ ] Limity kroków i wywołań narzędzi, wykrywanie pętli

## Wyjście (LLM10)
- [ ] Brak `innerHTML`/`<%==`/`v-html`/`dangerouslySetInnerHTML` z surowym wynikiem
- [ ] Markdown przez sanityzer z allowlistą; linki tylko `https:`/`mailto:`
- [ ] Obrazy z odpowiedzi nie ładowane automatycznie (lub allowlista/proxy)
- [ ] Sanityzacja na złożonym strumieniu, nie per fragment
- [ ] Wynik modelu nigdy do shell/eval; do SQL tylko parametryzowany
- [ ] CSP z ograniczonym `img-src` i `connect-src`

## Dane (LLM02, LLM09)
- [ ] Autoryzacja przed pobraniem (narzędzia, RAG)
- [ ] Filtr tenanta wewnątrz zapytania wektorowego + RLS
- [ ] Rozdzielone indeksy wg poziomu zaufania
- [ ] Minimalizacja/maskowanie PII wysyłanego do dostawcy
- [ ] Ustawienia dostawcy: brak trenowania na danych, retencja, DPA, region
- [ ] Usuwanie embeddingów przy usunięciu źródła

## Koszty i dostępność (LLM06)
- [ ] Rate limit per użytkownik/IP; limity tokenów
- [ ] Twardy limit kosztów (aplikacja + panel dostawcy)
- [ ] `max_tokens`, timeouty, przerwanie żądania przy rozłączeniu klienta
- [ ] Ochrona antybotowa dla czatu publicznego

## Łańcuch dostaw (LLM04, LLM05, ASI04)
- [ ] Przypięte wersje SDK/modeli/serwerów MCP; przegląd przed aktualizacją
- [ ] Hash opisów narzędzi MCP, alarm przy zmianie
- [ ] Bezpieczne formaty modeli (bez pickle)

## Dezinformacja i UX (LLM07, ASI09)
- [ ] Fakty biznesowe (ceny, statusy, zasady) z systemu, nie z modelu
- [ ] Oznaczenie, że użytkownik rozmawia z AI
- [ ] Źródła/cytaty przy odpowiedziach RAG

## WWW
- [ ] Sesje: `Secure; HttpOnly; SameSite`; CSRF dla żądań zmieniających stan
- [ ] CORS z allowlistą; WebSocket z weryfikacją `Origin`
- [ ] Błędy bez stack trace i kontekstu modelu
- [ ] Sekrety poza repozytorium; skan gitleaks

## Obserwowalność i reakcja
- [ ] Audyt wywołań narzędzi i decyzji polityk
- [ ] Alerty kosztów i prób injection
- [ ] Wyłącznik funkcji AI i procedura incydentu
- [ ] Testy regresyjne bezpieczeństwa (`testing-redteam.md`) w CI
