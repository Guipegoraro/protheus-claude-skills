# Protheus REST Server Configuration (appserver.ini)

TOTVS recommendation: dedicated appserver instance for REST only (never share with SOAP or user slaves).

## Standard REST server ([HTTPREST] family)

```ini
[General]
MAXSTRINGSIZE=10          ; REQUIRED, min 10 (requests > 1 MB)

[HTTPV11]
Enable=1
Sockets=HTTPREST          ; comma list allowed: HTTPREST,HTTPREST2

[HTTPREST]
Port=8080
IPsBind=                  ; empty = any server IP/DNS
URIs=HTTPURI              ; comma list allowed
Security=1                ; REQUIRED in production (see version notes)
InactiveTimeout=60        ; lib 20230403+
MaxRequests=0             ; 0 = unlimited per connection
; SSL/TLS — keys define the MINIMUM accepted version:
SSL2=0
SSL3=0
TLS1_2=1
TLS1_3=1
SSLCheckClientCert=0
SSLCertificateCA=         ; absolute CA path

[HTTPURI]
URL=/rest                 ; base path
PrepareIn=ALL             ; or "01,10" (empresa,filial) — each prepared thread consumes license!
Instances=2,5,1,1         ; working threads (REQUIRED)
CORSEnable=1              ; REQUIRED =1 for external SPAs (standalone PO-UI apps)
AllowOrigin=*             ; or explicit origin list
; Public=class/path/get   ; endpoints WITHOUT auth — avoid
; NoTenant=class/path/get ; validates user only, skips empresa/filial
; Stateless=1             ; Intera licensing (license on demand)
; Module=46               ; per-module license id (ex.: Meu Coletor=46)

[HTTPJOB]
MAIN=HTTP_START
ENVIRONMENT=environment

[ONSTART]
jobs=HTTPJOB
RefreshRate=30
```

## Version-critical notes

- **12.1.33 (2021):** default flipped to REQUIRE auth when `Security` absent; classic ADVPL REST server discontinued — REST 2.0 (binary layer) takes over (`[HTTPV11] ADVPL=0/1` transition key; REST 2.0 default from lib 20210809 + AppServer ≥ 19.3.1.8).
- **12.1.2410 (2024):** `Security` can NO LONGER be disabled.
- `Security=0` (older versions, dev only) runs everything as administrator.
- TLS 1.3 from lib 20221128. Keys set the minimum version (enabling only TLS1_3 rejects 1.2 clients).
- Standard headers supported: `Accept-Language` (lib 20210628+, returns Content-Language), `x-erp-module` (lib 20211116+), `x-erp-database` AAAAMMDD (lib 20240115+), `TenantId: empresa,filial`.

## OAuth2 endpoints (served by this REST)

- `POST /api/oauth2/v1/token?grant_type=password` — credentials in headers `username`/`password`. Returns access_token (JWT, 1h) + refresh_token (24h) — durations NOT configurable.
- `POST /api/oauth2/v1/token?grant_type=refresh_token&refresh_token=<t>` — renews both.
- `GET /api/oauth2/v1/jwks` (lib 20210517+) — public keys.
- Protected API + expired/absent token → 401.

## MPP (Multi-Protocol Port) — embedded PO-UI apps

```ini
[Drivers]
Active=TCP
MULTIPROTOCOLPORT=1
[TCP]
TYPE=TCPIP
PORT=1234
[General]
App_Environment=Environment_Name
```

- The MPP hosts a SEPARATE REST 2.0 instance (active when `App_Environment` is set) EXCLUSIVE to embedded apps opened via FwCallApp — external origins get a CORS error BY DESIGN. It can coexist with [HTTPREST] (MPP for embedded apps, HTTPREST for portals/standalone).
- Web access: `https://server:<mpp-port>/webapp/`; app resources under `/app-root/`.
- Requirements: AppServer 19.3.1.2+ (Lobo-guará), lib 20201123+.

## tlppCore standalone HTTP server (env-agnostic APIs)

```ini
[HTTPSERVER]
Enable=1
Servers=HTTP_SSL_SERVER

[HTTP_SSL_SERVER]
port=444
SslCertificate=cert.crt        ; presence of both SSL keys => HTTPS
SslCertificateKey=key.pem
locations=HTTP_ROOT

[HTTP_ROOT]
Path=/totvs                    ; virtual path → https://ip:444/totvs/<endpoint>
```

Use for TLPP APIs detached from the Protheus environment (own auth via tlpp-oAuth2 — github.com/totvs/tlpp-oAuth2).

## Operational gotchas

- New/changed WSRESTFUL class compiled after HTTP_START → **restart the AppServer** to register.
- Working threads reuse the environment: never leave open queries/filters/areas.
- `PrepareIn` per empresa/filial multiplies license usage across threads.
- Mingle gateway (internet exposure without opening REST): needs public IP + firewall allowing mingle.totvs.com.br IPs; params MV_MINGIUS/MV_MINGTOK/MV_MINGURL; irrelevant for embedded apps.

TDN references: pageId=185747842 (REST config), pageId=519719292 (mobile apps + Mingle IPs), "Entendendo as novidades do REST", pageId=465383509 (OAuth2 token), "Nova interface do Protheus com PO UI".
