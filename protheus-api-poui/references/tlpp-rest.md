# Building REST APIs in Protheus (TLPP annotations & WSRESTFUL)

## Which model to use

| Model | Business layer | Protheus env | Status |
|---|---|---|---|
| REST ADVPL (legacy server) | WSRESTFUL | Yes | Discontinued as of 12.1.33 |
| REST 2.0 (current) | WSRESTFUL (compat) AND TLPP annotations | Yes | **Default** (lib 20210809+, AppServer ≥ 19.3.1.8); up to 3x faster |
| REST tlppCore standalone | TLPP annotations | NO env (agnostic, own auth) | For APIs detached from the ERP |

**New endpoints: prefer TLPP annotations.** WSRESTFUL only when maintaining existing sources or matching a legacy codebase.

## TLPP annotations (current model)

```tlpp
#include 'tlpp-core.th'
#include 'tlpp-rest.th'

@Get("/api/myapp/v1/products")
User Function GetProds()
    Local jQuery   := oRest:getQueryRequest()       // JsonObject: page, pageSize, search, order, filters
    Local nPage    := Max(Val(jQuery:GetJsonText("page")), 1)   // contrato: page default 1
    Local jResp    := JsonObject():New()
    // ... build items honoring page/pageSize/order/search (contract: see totvs-contract section)
    jResp["items"]   := aItems
    jResp["hasNext"] := lHasNext
Return oRest:setResponse(jResp:toJson())

@Post("/api/myapp/v1/products")
User Function PostProd()
    Local jBody := JsonObject():New()
    jBody:fromJson( oRest:getBodyRequest() )
    If Empty(jBody:GetJsonText("code"))
        oRest:setStatusCode(400)
        Return oRest:setFault('{"code":"PRD001","message":"Código é obrigatório","detailedMessage":"Campo code ausente no body"}')
    EndIf
    // ...
Return oRest:setResponse(cJsonCreated)

@Get("/api/myapp/v1/products/:id")
User Function GetProd()
    Local jPath := oRest:getPathParamsRequest()     // by name: jPath:GetJsonText("id")
    ...
```

Key facts:
- Verbs: `@Get, @Post, @Put, @Patch, @Delete` (TLPP HAS PATCH; WSRESTFUL does not). Named form: `@Get(endpoint="/api/...")`. Works on Function, User Function and class methods.
- **There are NO `@QueryParam`/`@BodyParam`/`@PathParam` annotations** — everything is read at runtime from the global `oRest`:
  - `getQueryRequest()` / `getPathParamsRequest()` → JsonObject; `getBodyRequest()` → string (parse with `JsonObject():fromJson()`)
  - `getHeaderRequest()`, `getHeaderResponse()`, thread-pool data getters
  - `setResponse(cJson)`, `setStatusCode(n)`, `setFault(cJson)`
- **WARNING (TDN):** JsonObjects returned by `oRest:get*Request()` are REFERENCES to the internal REST object — never mutate them (state leaks across requests).
- Path-param name collision: `/x/:id` vs `/x/:codigo` on the same base → the FIRST registered route's name wins.
- Extras: native OpenAPI generation, onAuth hook, thread lifecycle hooks, trace logs. Dynamic routes possible via a JSON-returning registrar function.
- Official examples incl. side-by-side FWREST→TLPP migration: https://github.com/totvs/tlpp-sample-rest (`server/migrate-FWrest-2-tlpp`).

## WSRESTFUL (legacy — maintenance only)

```advpl
#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL sample DESCRIPTION "Exemplo" FORMAT APPLICATION_JSON
    WSDATA page     AS INTEGER OPTIONAL
    WSDATA pageSize AS INTEGER OPTIONAL
    WSMETHOD GET  ALL DESCRIPTION "Lista"  PATH "/sample"      TTALK "v1"
    WSMETHOD GET  ID  DESCRIPTION "Um"     PATH "/sample/{id}" TTALK "v1"
    WSMETHOD POST     DESCRIPTION "Inclui" PATH "/sample"      TTALK "v1"
END WSRESTFUL

WSMETHOD GET ALL WSRECEIVE page, pageSize WSSERVICE sample
    ::SetContentType("application/json")
    DEFAULT ::page := 1, ::pageSize := 20
    ::SetResponse('{"items":[...],"hasNext":true}')
Return .T.

WSMETHOD POST WSSERVICE sample
    Local cBody := ::GetContent()
    If Empty(cBody)
        SetRestFault(400, "body é obrigatório")
        Return .F.
    EndIf
Return .T.
```

- Verbs: GET/POST/PUT/DELETE only. `cId` (ALL/ID/...) allows several methods per verb. `SECURITY "MATA030"` ties privilege check to a routine; `NOTENANT` skips TenantId validation.
- Query params: declare `WSDATA` + receive with `WSRECEIVE` (→ `::param`). Path params: `::aURLParms` (positional) or `PATHPARAM p1,p2` (named → `::p1`). Headers: `HEADERPARAM`.
- Errors: `SetRestFault(nCode, cMessage, [lJson], [nStatus], [cDetailMsg], [cHelpUrl], [aDetails])` — the last 3 only serialize when the WSMETHOD carries `TTALK "v1"` (which switches errors from legacy `{errorCode, errorMessage}` to the TOTVS standard `{code, message, detailedMessage, helpUrl, details}`). **Always use `TTALK "v1"` — PO-UI expects the standard format.**
- Return .T./.F. from methods. New/changed REST classes require an **AppServer restart** to register.
- Working threads are reused: never leave open queries, dirty filters or positioned areas behind.

## FWAdapterBaseV2 — standard-contract adapter over SQL (ADVPL)

Official adapter implementing pagination, OData `filter`, `order` and `fields` from the TOTVS guide over a query. Supports `?pagesize&page`, `?filter=code eq '000001'` (lib 20220322+ has toupper()), `?order=`, `?fields=`; response includes `remainingRecords` (lib 20220502+) and `total` (lib 20250519+). Use it when the endpoint is essentially "query a table with the standard contract". TDN: "09. FWAdapterBaseV2".

## FWRestModel — zero-code REST over MVC models

```advpl
PUBLISH MODEL REST NAME products SOURCE MyMVCSource            // ModelDef exposed
PUBLISH USER MODEL REST NAME myUserModel ...                   // user models
```
Exposes the model at `http://server:port/fwmodel/<name>[/<PK-base64>]`. Customize by inheriting `FwRestModel` (`RESOURCE OBJECT <class>`): GetData/SaveData/DelData, SetFilter, Seek/Skip/Total, SetFields, DecodePK, Get/SetStatusResponse... Good for quick admin CRUD over existing MVC models; the fwmodel JSON shape is the MVC model structure, NOT the PO-UI `{items, hasNext}` contract — for po-page-dynamic-* prefer a TLPP/adapter endpoint.

## Framework generic services (reuse before building)
- `BasicProtheusServices` / `fwformstructview` — SX3 structure via REST (feeds dynamic metadata)
- `GenericLookupService` — standard F3 lookup via REST (pairs with po-lookup)
