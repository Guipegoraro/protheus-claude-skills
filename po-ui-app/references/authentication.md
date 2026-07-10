# Authentication: PO-UI App ↔ Protheus REST (standalone mode)

For apps running OUTSIDE Protheus (browser/standalone) against the standard `[HTTPREST]` server. Embedded apps skip all of this — the ERPTOKEN interceptor handles auth (see protheus-embedded.md).

## Protheus OAuth2 endpoints (LIB 20190705+)

Get token — credentials go in HTTP HEADERS (use HTTPS; without SSL the server logs a warning per request):
```
POST {base}/api/oauth2/v1/token?grant_type=password
Headers:
  username: <protheus user>
  password: <password>
```
Response:
```json
{
  "access_token": "<JWT>",
  "refresh_token": "<token>",
  "scope": "default",
  "token_type": "Bearer",
  "expires_in": 3600,
  "hasMFA": false
}
```
(`hasMFA` only exists from release 20241007+.)
- Access token: 1h. Refresh token: 24h. NOT configurable. `grant_type` accepts only `password` and `refresh_token`.
- Refresh (renews BOTH tokens — indefinite cycle while refresh is valid):
  `POST {base}/api/oauth2/v1/token?grant_type=refresh_token&refresh_token=<token>`
- Expired token on a protected API → HTTP 401.
- JWKS (LIB 20210517+): `GET {base}/api/oauth2/v1/jwks` (RS256/RS512, RFC 7517) for signature validation.
- Every API call: `Authorization: Bearer <access_token>`.

## Recommended Angular wiring

There is NO official TOTVS recipe for po-page-login + Protheus OAuth2 (confirmed gap) — implement it:

1. `po-page-login` WITHOUT `p-authentication-url` (the built-in Basic/Bearer contracts do not match the Protheus header-based token endpoint). Handle `p-login-submit`:
```typescript
onLoginSubmit(login: PoPageLogin): void {
  this.http.post<TokenResponse>(`${base}/api/oauth2/v1/token?grant_type=password`, null, {
    headers: { username: login.login, password: login.password, 'X-PO-No-Message': 'true' }
  }).subscribe({ next: t => { this.tokenStore.save(t); this.router.navigate(['/']); },
                 error: () => this.poNotification.error('Usuário ou senha inválidos') });
}
```
2. HTTP interceptor: attach `Authorization: Bearer` to every request; on 401, try one refresh, replay the request; on refresh failure, redirect to login. Keep tokens in sessionStorage (mirrors the ERPTOKEN convention used by FwCallApp).
3. Multi-tenant: send `TenantId: <empresa>,<filial>` header when the endpoint needs branch context (endpoints declared NOTENANT skip it).

## CORS (server side — required for standalone SPA)

In the Protheus REST section (see protheus-api-poui skill → appserver-config.md):
```ini
[HTTPURI]
CORSEnable=1
AllowOrigin=*        ; or explicit origins
```
Remember: the MPP REST intentionally rejects external origins — standalone apps must target the standard [HTTPREST] port.

## Exposure over the internet — Mingle (optional gateway)

TOTVS SaaS gateway (auth delegation + API gateway + metrics) to reach on-premises Protheus without exposing REST. Needs public-IP appserver, firewall allowing mingle.totvs.com.br IPs, alias per company (request at mingle.totvs.com.br/landpage). Params ex.: MV_MINGIUS, MV_MINGTOK, MV_MINGURL. Irrelevant for embedded apps.

## Security notes
- Since 12.1.2410 REST auth cannot be disabled (`Security` forced on); 12.1.33 made auth the default. `Security=0` (pre-12.1.2410 only, dev only) runs everything as admin.
- `Public=` URI key exposes endpoints without auth — avoid unless truly public.
- Password never in URL/query; the Protheus contract uses headers. Always HTTPS in production.
