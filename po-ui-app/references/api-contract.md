# PO-UI / TOTVS REST API Contract

The exact REST contract that PO-UI data-driven components expect and that TOTVS mandates for all product APIs. The backend (Protheus or any other) MUST implement this contract for `po-page-dynamic-*`, `po-lookup`, `po-table` pagination and `po-page-job-scheduler` to work out of the box.

Sources: https://po-ui.io/guides/api (frontend contract) + Guia de implementação das APIs TOTVS (https://tdn.totvs.com/display/public/INT/Guia+de+implementacao+das+APIs+TOTVS).

## 1. Collection responses (GET list)

```json
{
  "hasNext": true,
  "items": [ { }, { } ],
  "_messages": [ ]
}
```

- `hasNext` (boolean) — REQUIRED on every paginated response. TOTVS validator enforces `items` + `hasNext` together.
- `items` (array) — the page records.
- Optional extras allowed by TOTVS guide: `total`, `remainingRecords` (FWAdapterBaseV2 lib 20220502+ returns `remainingRecords`, lib 20250519+ returns `total`).

## 2. Single-entity responses (GET one, POST, PUT)

Return the entity directly, no wrapper:

```json
{ "id": 10, "name": "John", "surname": "Doe" }
```

Optional `_messages` array (each item in the error format below, with `type`: `success | warning | error | information`) — the PO-UI `po-http-interceptor` shows them as notifications automatically.

Optional `_expandables: ["communities", ...]` listing expandable sub-entities (TOTVS guide).

## 3. Error responses (HTTP 4xx / 5xx)

Return the error object directly:

```json
{
  "code": "error identifier",
  "message": "user-facing literal, in the request language",
  "detailedMessage": "technical detail",
  "helpUrl": "optional docs link",
  "type": "error | warning | information (optional, default error)",
  "details": [ { "code": "...", "message": "...", "detailedMessage": "..." } ],
  "detailTitle": "optional title used by po-http-interceptor"
}
```

`code`, `message`, `detailedMessage` are required for the PO-UI interceptor to display them. `details` is recursive.

HTTP status usage (TOTVS): 4xx = business/request error (401 unauthenticated, 403 no permission, 404 not found, 400 business rule, 409 conflict/duplicate); 5xx = unexpected (503 overload, 507 out of disk).

## 4. Query parameters for collections

| Param | Semantics |
|---|---|
| `page` | Page number, integer > 0, default 1 |
| `pageSize` | Records per page, integer > 0 (dynamic-table default 10; lookup 20; TOTVS default 20) |
| `order` | Comma list; `-` prefix = descending. `order=name,-age,surname` |
| `property=value` | Simple field filter: `?name=john&surname=doe`. Nested: `parent.child=value`. Lists: comma-joined `?name=Tony,Peter` |
| `search` | Quick-search text (convention of po-page-dynamic-table / dynamic-search / job-scheduler) |
| `filter` | Search text of the po-lookup modal (NOT the same as `search`) |
| `fields` | Restrict returned fields: `fields=name,age` (takes precedence over expand) |
| `expand` | Expand sub-entities up to 2 levels: `expand=communities.permissions`; expanded sub-collections should stay ≤ 20 records (else dedicated endpoint) |

Pagination multiplier semantics: `page=2&pageSize=20` → records 21–40.

Optional complex filters (TOTVS guide): OData v4 subset — `filter=code eq '000001'`, operators eq/ne/gt/ge/lt/le/and/or/not, grouping. FWAdapterBaseV2 implements this on the Protheus side.

## 5. Endpoint map consumed by PO-UI components

| Operation | Verb / route |
|---|---|
| List | `GET {api}?page&pageSize[&order][&filters][&search]` |
| Get one | `GET {api}/{id}` |
| Create | `POST {api}` (payload = form values) |
| Update | `PUT {api}/{id}` |
| Delete | `DELETE {api}/{id}` |
| Delete many (removeAll) | `DELETE {api}` with body = array of key objects |
| Metadata | `GET {api}/metadata?type={list\|edit\|detail}&version={cachedVersion}` or dedicated `serviceMetadataApi` (GET) |
| Page customization | `POST {serviceLoadApi}` → PoPageDynamicTableOptions/... |
| Lookup by value | `GET {api}/{value}` (or `GET {api}?{fieldValue}=1,2` for multiple) |
| Job scheduler | `GET {api}/processes[?search=]`, `GET {api}/processes/{id}/parameters`, `POST {api}`, `GET/PUT {api}/{id}`, availability probe `HEAD {api}/processes` |
| Login (po-page-login) | `POST {authUrl}` — Basic: header `Authorization: Basic b64(login:password)` + body `{rememberUser}`; Bearer: body `{login, password: b64, rememberUser}`. 200 → `{user}` saved to sessionStorage; 400/401 → error object + optional `maxAttemptsRemaining`, `loginWarnings`, `passwordWarnings` |

Metadata response shape: `{ version, title, fields: [{property, key, label, disabled, ...}], keepFilters, ... }`. On metadata fetch error, PO-UI falls back to the browser-cached version.

## 6. X-PO-* control headers

Sent by the frontend and STRIPPED by PO-UI interceptors before the request leaves — the backend never sees them. They control PO-UI behavior only:

- `X-PO-No-Message: true` — suppress success/error notifications
- `X-PO-No-Error: true` — suppress 4xx/5xx notifications
- `X-PO-Screen-Lock: true` — lock screen with loading overlay (dynamic pages and job-scheduler services send it by default)
- `X-PO-No-Count-Pending-Requests: true` — skip the pending-request counter

Requires `PoHttpInterceptorService` / `PoHttpRequestInterceptorService` registered (via `provideHttpClient(withInterceptorsFromDi())` + PoHttpRequestModule).

## 7. TOTVS URL and versioning standard

- URL: `{host}/api/{grouper}/{domain}/{version}/{resource}` — e.g. `/api/framework/v1/users`. Resources plural, no verbs in URL, ≤ ~3 path levels, camelCase or kebab-case.
- Version `v{major}[.{minor}]` (v1, v1.5). New MAJOR required when: removing/renaming URI, removing response field, removing verb, new mandatory param. NOT required for: new optional params, new response properties.
- Dates: ISO-8601 (`yyyy-mm-ddThh:mm:ss±hh:mm`).
- Content-Type: `application/json` (XML only when legally required).
- Async operations: 202 + `Location` header → poll `{"status":"pending","progress":"30%","canCancel":true}` → 303 + Location when done → 410 Gone if expired.
- Standard types/params ready to reuse: `totvsApiTypesBase.json` in https://github.com/totvs/ttalk-standard-message (Paging, ErrorModel, Order/Page/PageSize/Fields/Expand params).

## 8. PO Sync contract (offline-first apps)

- Every record needs a logical-deletion boolean field (e.g. `isDeleted`), mapped as `deletedField` in the PoSyncSchema.
- Diff endpoint: `GET {diffUrlApi}/{lastSyncDate ISO-8601}` →
  `{ "hasNext": false, "items": [], "po_sync_date": "2018-10-08T13:57:55.008Z" }`
  `po_sync_date` = server response time, used as cursor for the next sync (sync stops without it).
- Schema: `getUrlApi` (required), `diffUrlApi`, `deletedField`, `fields`, `idField`, `name`, `pageSize`; POST/DELETE/PATCH endpoints optional (default = getUrlApi).
