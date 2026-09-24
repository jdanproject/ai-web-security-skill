# Web Layer Hardening Around AI Features

AI features inherit all classic web application risks (OWASP Top 10, ASVS 5.0). Below is the minimum for chatbot/assistant endpoints.

## HTTP headers

```
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{RANDOM}'; style-src 'self'; img-src 'self' data: https://cdn.example.com; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
Cross-Origin-Opener-Policy: same-origin
```

Allowlisted `img-src` and `connect-src` block exfiltration via images/fetch in model output even if sanitization fails.

Apache:
```apache
Header always set Content-Security-Policy "default-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
```

## Sessions and authentication

- Cookies: `Secure; HttpOnly; SameSite=Lax` (or `Strict`), rotate session ID on login.
- Authenticated chat endpoints check the session on every request, including WebSocket/SSE.
- CSRF token for state-changing requests (chat POSTs that trigger actions).

## CORS

- No `Access-Control-Allow-Origin: *` on chat endpoints. Allowlist specific origins; `Allow-Credentials` only with a specific origin.
- Chat widget embedded on other domains: separate endpoint with a widget token, no access to logged-in admin user data.

## Rate limiting and bot protection

- At web server / reverse proxy level (mod_evasive, mod_security, nginx `limit_req`, Cloudflare) **and** in the application (per user, per tokens).
- CAPTCHA/Turnstile for anonymous chat after a threshold.
- fail2ban on abuse patterns in application logs.

## File uploads to AI

- Type allowlist (verify magic bytes, not extension), size limit, AV scan.
- Store outside webroot, random names, serve with `Content-Disposition: attachment`.
- Parse in an isolated process with limits.

## Secrets

- Provider API keys in environment variables / secrets manager, file mode `600`, never in the repository (`.gitignore`, gitleaks in CI).
- Separate keys per environment (dev/stage/prod) and per feature; spend limits set at the provider.
- Key rotation and a leak response procedure.

## Errors and logs

- Error messages without stack traces, prompts, model names or context fragments.
- Logs without full keys, passwords, session tokens; strip control characters.

## Dependencies

- `npm audit` / `cpan-audit` / Dependabot / Renovate; pinned versions (lockfile, `cpanfile.snapshot`).
- Upgrade AI provider SDKs deliberately (review changelogs).
