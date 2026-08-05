---
name: protheus-api-poui
description: Creates REST APIs in Protheus (TLPP annotations, WSRESTFUL, FWAdapterBaseV2) following the TOTVS API standard consumed by PO-UI frontends. Use when writing @Get/@Post TLPP endpoints, WSRESTFUL services, configuring the Protheus REST server (appserver.ini, OAuth2, CORS, MPP), or serving data to po-page-dynamic components.
---

# Protheus REST APIs for PO-UI (TOTVS standard)

Backend counterpart of skill `po-ui-app`. The integration point is the TOTVS API contract — implement it exactly and the PO-UI dynamic pages work with zero frontend code.

> Skill `tlpp-rest-endpoint-generator` covers the detailed `oRest`/TTALK reference.

**Output language rule: all user-facing output — code comments, commit messages, chat responses — in PT-BR. Identifiers in English/Protheus conventions.**

## Workflow for a new endpoint

1. **Model choice** — default to **TLPP annotations** (`@Get/@Post/@Put/@Patch/@Delete`); WSRESTFUL only for legacy maintenance; `FWAdapterBaseV2` when it's "standard contract over a SQL query"; `FWRestModel` (PUBLISH MODEL REST) for quick CRUD over existing MVC models (but its JSON is NOT the `{items, hasNext}` shape). Syntax and rules: [references/tlpp-rest.md](references/tlpp-rest.md).
2. **URL** — TOTVS standard: `/api/{grouper}/{domain}/v1/{resource}`, resource plural, no verbs in path, camelCase/kebab-case.
3. **Contract** — collections MUST return `{"items": [...], "hasNext": bool}` and honor `page` (default 1), `pageSize`, `order` (`-field` = desc), simple filters `?field=value`, `search` (quick search of dynamic-table) and `filter` (po-lookup modal). Multiplier semantics: `page=2&pageSize=20` → records 21–40. Full contract lives in the frontend skill: read `~/.claude/skills/po-ui-app/references/api-contract.md` (single source of truth — do not duplicate).
4. **Errors** — always `{code, message, detailedMessage}` (+optional helpUrl/details) with proper 4xx/5xx. In WSRESTFUL that requires the `TTALK "v1"` flag on every WSMETHOD; in TLPP build the JSON yourself with `oRest:setStatusCode()` + `setFault()`. `message` in PT-BR (user-facing), `detailedMessage` technical.
5. **Metadata (optional but powerful)** — implementing `GET {api}/metadata?type=list|edit|detail` lets po-page-dynamic-* build screens from the server. Reuse `fwformstructview`/`BasicProtheusServices` for SX3-driven metadata; `GenericLookupService` for F3 lookups.
6. **Server config** — check/document the appserver.ini requirements (REST section, CORS for standalone apps, MPP for embedded apps, OAuth2): [references/appserver-config.md](references/appserver-config.md). Endpoint for an embedded app? It's served by the MPP REST (external origins CORS-blocked by design). Standalone SPA? `[HTTPURI] CORSEnable=1` + AllowOrigin.

## Mandatory code rules (project conventions apply on top)

- SQL: FWPreparedStatement, `D_E_L_E_T_ = ' '`, branch filter, RetSqlName — per the user's global ADVPL rules.
- Never leave open queries/dirty filters in REST methods — working threads are reused across requests.
- TLPP: never mutate JsonObjects returned by `oRest:get*Request()` (they are internal references — state leaks between requests).
- Function names: unique within the first 10 chars (C2021).
- No dictionary updates (SX3/SX6/SIX) via source — Configurador only (user's global rule).
- Business rules (blocking/validation that rejects operations) need a client source — otherwise permissive fallback + log + open question, per the user's global rule.
- WSRESTFUL new/changed class → AppServer restart required.

## Auth quick reference

- Token: `POST /api/oauth2/v1/token?grant_type=password` (credentials in HEADERS username/password; HTTPS). Access 1h / refresh 24h, not configurable. Refresh: `grant_type=refresh_token`. 401 on expiry.
- Embedded apps skip OAuth2 — FwCallApp injects ERPTOKEN for the logged user.
- Since 12.1.2410 `Security` cannot be disabled; `Public=` URI key bypasses auth (avoid).
- Multi-tenant: `TenantId: empresa,filial` header; `NOTENANT`/NoTenant skips it.

## Verification

- Compile; if WSRESTFUL, restart AppServer; smoke-test with curl: list (`?page=1&pageSize=5`), pagination boundaries (`hasNext` correctness on last page), one filter, `order=-field`, a 4xx path (assert `{code,message,detailedMessage}`).
- If it feeds a po-page-dynamic-*, test through the component or against the endpoint map in the po-ui-app skill.

## Live sources

- TLPP REST docs: https://tdn.totvs.com/display/tec/REST · samples: https://github.com/totvs/tlpp-samples and https://github.com/totvs/tlpp-sample-rest
- TOTVS API guide: TDN "Guia de implementacao das APIs TOTVS" · standard types: https://github.com/totvs/ttalk-standard-message
- WSRESTFUL/SetRestFault/FWAdapterBaseV2/FWRestModel: TDN framework space (search by name)
- MCP `advpl-tlpp-mcp-docs` (reference base, NOT client env): function/class docs, standard-source search
- MCP `po-ui` (official PO-UI docs): check what the consuming frontend component actually sends/expects when in doubt about the contract
- Official TOTVS AI skills for ADVPL/TLPP: https://github.com/totvs/engpro-advpl-tlpp-skills
