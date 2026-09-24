# Agenci, narzędzia i MCP

## OWASP Top 10 for Agentic Applications 2026

| ID | Ryzyko | Kluczowa kontrola |
|---|---|---|
| ASI01 | Agent Goal Hijack – przejęcie celu przez wstrzyknięte instrukcje lub zatrute treści | Oddzielenie danych od instrukcji, weryfikacja planu przed akcjami wrażliwymi |
| ASI02 | Tool Misuse and Exploitation – nadużycie legalnych narzędzi | Wąskie narzędzia, schematy, polityki per wywołanie |
| ASI03 | Identity and Privilege Abuse | Działanie w kontekście użytkownika, krótkotrwałe poświadczenia, brak kont „super-agenta” |
| ASI04 | Agentic Supply Chain Vulnerabilities | Weryfikacja serwerów MCP, skilli, pluginów, przypięte wersje |
| ASI05 | Unexpected Code Execution (RCE) | Brak `eval`/shell; jeśli kod konieczny – izolowany sandbox bez sieci |
| ASI06 | Memory and Context Poisoning | Walidacja zapisów do pamięci, izolacja per użytkownik, możliwość czyszczenia |
| ASI07 | Insecure Inter-Agent Communication | Uwierzytelnione kanały, wiadomości od innych agentów = niezaufane dane |
| ASI08 | Cascading Failures | Limity kroków, wyłączniki, izolacja błędów |
| ASI09 | Human-Agent Trust Exploitation | Potwierdzenia pokazujące surowe operacje, bez perswazyjnych streszczeń |
| ASI10 | Rogue Agents | Monitoring zachowania, kill switch, audyt |

## Projektowanie narzędzi (function calling)

1. **Inwentarz**: lista wszystkich narzędzi, ich uprawnień i poświadczeń, właściciel.
2. **Minimalizm**: tylko narzędzia potrzebne do zadania. Czat informacyjny nie potrzebuje narzędzi zapisujących.
3. **Wąskie operacje**: `get_order_status(order_id)` zamiast `run_sql(query)`; `send_reset_link()` zamiast `send_email(to, body)`.
4. **Ścisły schemat**: JSON Schema z `additionalProperties: false`, typy, zakresy, wzorce, enumy. Walidacja **po stronie serwera** (ajv / JSON::Validator) – model może zignorować schemat.
5. **Kontekst użytkownika**: wykonawca narzędzia dokleja `user_id`/`tenant_id` z sesji. Parametry identyfikujące właściciela nigdy nie pochodzą od modelu.
6. **Polityka przed wykonaniem**: deterministyczny silnik reguł sprawdza (kto, co, na czym, ile razy) w momencie wykonania.
7. **Poziomy ryzyka**:
   - odczyt własnych danych → automatycznie,
   - zapis odwracalny → automatycznie z logiem i limitem,
   - nieodwracalne/finansowe/komunikacja zewnętrzna → potwierdzenie człowieka z podglądem surowych parametrów.
8. **Wyniki narzędzi** wracają do modelu jako niezaufane dane (mogą zawierać injection, np. treść e-maila, strony www).
9. **Limity**: max liczba wywołań na turę i sesję, wykrywanie pętli (te same wywołania powtarzane), timeouty.

## Łańcuch „lethal trifecta”

Najgroźniejsza kombinacja w jednym agencie:
1. dostęp do danych prywatnych,
2. ekspozycja na niezaufane treści,
3. możliwość komunikacji na zewnątrz (HTTP, e-mail, obrazy w odpowiedzi).

Jeśli agent ma wszystkie trzy – **usuń co najmniej jedną nogę** (np. brak wyjścia sieciowego, brak renderowania obrazów, rozdzielenie na dwa agenty z różnymi uprawnieniami) albo wymagaj potwierdzenia każdej komunikacji zewnętrznej.

## Wzorce architektoniczne

- **Dual LLM / quarantined LLM**: model uprzywilejowany (z narzędziami) nigdy nie widzi surowych treści niezaufanych; model kwarantannowy przetwarza treści i zwraca wynik o ścisłej strukturze (np. enum, liczby), bez wolnego tekstu.
- **Plan-then-execute**: plan akcji ustalany przed kontaktem z niezaufanymi danymi; dane nie mogą dodać nowych akcji.
- **Egress allowlist**: sandbox narzędzi z wyjściem sieciowym tylko do określonych domen (proxy filtrujące).

## MCP (Model Context Protocol)

### Serwer MCP (jeśli go tworzysz)
- Transport HTTP: uwierzytelnianie OAuth 2.1 zgodnie ze specyfikacją MCP Authorization; serwer jako resource server, weryfikacja `aud` tokenu – **odrzucaj tokeny wystawione dla innych zasobów** (zakaz token passthrough).
- Wąskie zakresy (scopes), osobne poświadczenia per serwer, krótkie TTL.
- Walidacja wejścia każdego narzędzia jak w publicznym API.
- Opisy narzędzi statyczne i przejrzane – opis jest częścią promptu modelu.
- Transport lokalny (stdio): uruchamiaj z minimalnymi uprawnieniami systemowymi; zakaz nasłuchu na `0.0.0.0` bez uwierzytelnienia; ochrona przed DNS rebinding (walidacja `Origin`/`Host`).
- Sesje: identyfikatory losowe, niepowiązane z autoryzacją; autoryzacja weryfikowana przy każdym żądaniu.

### Klient / host MCP (jeśli podłączasz cudze serwery)
- Tylko serwery z zaufanych źródeł, przypięte wersje, przegląd kodu i opisów narzędzi.
- Ochrona przed **tool poisoning** (ukryte instrukcje w opisach narzędzi) i **rug pull** (zmiana opisów po zatwierdzeniu) – porównuj hash opisów, alarmuj przy zmianie.
- Ochrona przed **tool shadowing** – unikalne przestrzenie nazw narzędzi per serwer.
- Potwierdzenie użytkownika dla narzędzi zapisujących; pokazywanie pełnych argumentów.
- Izolacja: każdy serwer w osobnym kontenerze/użytkowniku, egress przez proxy filtrujące.
- Confused deputy przy proxy OAuth: zgoda użytkownika per klient, walidacja `redirect_uri`.

## Pamięć agenta

- Zapisy do pamięci tylko z zaufanych ścieżek lub po walidacji; oznacz źródło każdego wpisu.
- Izolacja per użytkownik/tenant; brak współdzielonej pamięci między klientami.
- Użytkownik widzi i może usunąć swoją pamięć.
- TTL dla wpisów, okresowy przegląd anomalii.

## Wiele agentów

- Wiadomości między agentami uwierzytelnione (podpis/mTLS) i traktowane jak niezaufane dane.
- Agent nie dziedziczy uprawnień agenta wywołującego automatycznie.
- Limity rekurencji i głębokości delegacji.
