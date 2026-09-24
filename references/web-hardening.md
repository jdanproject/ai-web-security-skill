# Utwardzanie warstwy WWW wokół funkcji AI

Funkcje AI dziedziczą wszystkie klasyczne ryzyka aplikacji WWW (OWASP Top 10, ASVS 5.0). Poniżej minimum dla endpointów czatu/asystenta.

## Nagłówki HTTP

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'; style-src 'self'; img-src 'self' data: https://cdn.twojadomena.pl; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
```

`img-src` i `connect-src` ograniczone do allowlisty – blokuje eksfiltrację przez obrazy/fetch w odpowiedziach modelu nawet przy błędzie sanityzacji.

Apache:
```apache
Header always set Content-Security-Policy "default-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
```

## Sesje i uwierzytelnienie

- Ciasteczka: `Secure; HttpOnly; SameSite=Lax` (lub `Strict`), rotacja ID po logowaniu.
- Endpointy czatu wymagające logowania sprawdzają sesję przy każdym żądaniu, także w WebSocket/SSE.
- Token CSRF dla żądań zmieniających stan (POST czatu wywołującego akcje).

## CORS

- Endpoint czatu bez `Access-Control-Allow-Origin: *`. Allowlista konkretnych originów; `Allow-Credentials` tylko z konkretnym originem.
- Widget czatu osadzany na innych domenach: osobny endpoint z tokenem widgetu, bez dostępu do danych zalogowanego użytkownika panelu.

## Rate limiting i ochrona antybotowa

- Na poziomie serwera WWW / reverse proxy (mod_evasive, mod_security, nginx `limit_req`, Cloudflare) **oraz** w aplikacji (per użytkownik, per tokeny).
- CAPTCHA/Turnstile dla anonimowego czatu po przekroczeniu progu.
- fail2ban na wzorce nadużyć w logach aplikacji.

## Upload plików do AI

- Allowlista typów (weryfikacja magic bytes, nie rozszerzenia), limit rozmiaru, skan AV.
- Przechowywanie poza webrootem, losowe nazwy, serwowanie z `Content-Disposition: attachment`.
- Parsowanie w izolowanym procesie z limitami.

## Sekrety

- Klucze API dostawców w zmiennych środowiskowych / menedżerze sekretów, uprawnienia plików `600`, nigdy w repozytorium (`.gitignore`, gitleaks w CI).
- Osobne klucze per środowisko (dev/stage/prod) i per funkcja; limity wydatków ustawione u dostawcy.
- Rotacja kluczy i procedura na wypadek wycieku.

## Błędy i logi

- Komunikaty błędów bez stack trace, promptów, nazw modeli, fragmentów kontekstu.
- Logi bez pełnych kluczy, haseł, tokenów sesji; usuwanie znaków sterujących.

## Zależności

- `npm audit` / `cpan-audit` / Dependabot / Renovate; przypięte wersje (lockfile, `cpanfile.snapshot`).
- SDK dostawców AI aktualizowane świadomie (przegląd changelogów).
