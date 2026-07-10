# Running a PO-UI App Inside Protheus (FwCallApp + protheus-lib-core)

How to embed an Angular/PO-UI app in the Protheus menu (webapp/smartclient) — the mode that consumes NO extra licenses.

## Licensing (decides the architecture — literal TDN quote)
1. App executed inside Protheus via `FwCallApp` + Multi-Protocol Port (MPP) + protheus-lib-core → **no additional license consumed**.
2. App executed via browser against the standard REST → consumes standard REST licenses.

Also: the MPP's own REST instance is EXCLUSIVE to embedded apps — external requests get a CORS error ON PURPOSE (documented). Standalone apps must use the regular `[HTTPREST]` server instead.

## Server prerequisites (appserver.ini)

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

AppServer Lobo-guará 19.3.1.2+, Lib 20201123+. Web access: `https://server:<mpp-port>/webapp/`. `AmIOnRestEnv()` checks MPP; `FwCallApp(..., lUseOnBoarding=.T.)` (LIB 20230626+) opens a wizard if config is missing.
Common errors: ERR_CERT_AUTHORITY_INVALID / ERR_SSL_VERSION_OR_CIPHER_MISMATCH (MPP certificate), ERR_EMPTY_RESPONSE (threads killed by patch apply), "Aplicativo não encontrado" (.app not in RPO or missing index.html), 404 (delete extracted folder under app-root and reopen).

## Packaging rules for the .app (MANDATORY checklist)

1. Angular build output with `index.html` at root; `<base href="/">` in head.
2. ZERO external resources — no CDN; everything bundled.
3. All files inside a folder named after the app, ALL LOWERCASE.
4. Zip the folder → rename `.zip` to `.app`.
5. Compile the `.app` as a RESOURCE in the RPO (deployed/updated via patch like any source).
6. Backend communication → `/assets/data/appconfig.json`:
   ```json
   { "name": "My App", "version": "1.0.0", "api_baseUrl": "/" }
   ```
   With `api_baseUrl: "/"`, FwCallApp rewrites it at extraction time to the real REST address — the SAME build works on any environment, no rebuild. (Old keys serverBackend/restEntryPoint are replaced by api_baseUrl.) Do NOT hardcode the server in environment.ts.
7. Angular routes: add a route for `index.html` → main component.

Runtime: extracted to `protheus_data/http-root/app-root/<app>/`; base href adjusted; preload stores in sessionStorage: `ERPTOKEN` (Bearer of the logged Protheus user), company group + branch (LIB 20210405+), dDataBase (LIB 20240115+). Empty file `noredirect` at app root skips preload.

## Opening from the menu (ADVPL side)

```advpl
Function ExecMyApp()
    FwCallApp("my-app-name")   // .app resource name
Return
```

## @totvs/protheus-lib-core (Angular side)

Install. Published majors are ONLY 14/15/17/19/21 (matching Angular/PO-UI majors) — there is no lib-core 16/18/20; on those Angular majors, embedded apps stay on the previous published major. v19 needs `--force` due to a PO-UI dep inconsistency:
```bash
ng add @po-ui/ng-components@latest
ng add @po-ui/ng-templates@latest
npm i subsink
npm i @totvs/protheus-lib-core@latest
```
Peer deps also require `@totvs/po-theme` (TOTVS theme — embedded apps use it, not the plain PO theme) and `@totvs/common-assets`. Not open source; docs: https://tdn.totvs.com.br/display/framework/Protheus-lib-core · registry: https://npm.totvs.io

Standalone bootstrap:
```typescript
providers: [
  provideRouter(routes),
  provideHttpClient(withInterceptorsFromDi()),
  importProvidersFrom([BrowserAnimationsModule, PoHttpRequestModule, ProtheusLibCoreModule]),
]
```

Importing `ProtheusLibCoreModule` auto-enables 4 interceptors: auth (attaches ERPTOKEN Bearer to every request), URL (completes relative URLs to the MPP REST — just call relative endpoints), context (company group/branch header), language (`Content-Language`, LIB 20221128+).

### Services (all confirmed in real code)
- `ProAppConfigService` — `insideProtheus(): boolean` (detect embedded vs standalone), `callAppClose()` (close the hosting dialog)
- `ProSessionInfoService` — getAppName(), getBranch(), getCompany(), getDataBase(), getModule()
- `ProBranchService.getUserBranches()` / `ProCompanyService.getUserCompanies()`
- `ProUserAccessService` — `aliasHasAccess(alias)`, `userHasAccess(routine, action)` → `{access, message}`
- `ProGenericAdapterService` — generic dictionary CRUD: `list({alias: 'SA1'})` → `{items}` (no custom backend needed)
- `ProDateService.getDateFormat(language)`, `ProJsToAdvplService` (JS↔ADVPL bridge), `ProThemeService`, `ProUserInfoService`, `ProThreadInfoService`, `ProUserProfileService`

### Hybrid pattern (same app inside AND outside Protheus)
```typescript
private readonly proAppConfig = inject(ProAppConfigService);
ngOnInit(): void {
  if (this.proAppConfig.insideProtheus()) {
    // session inherited: interceptors handle token/URL/context
  } else {
    // standalone dev/browser: own auth (OAuth2 — see authentication.md);
    // common dev fallback: interceptor injecting Basic auth when no ERPTOKEN in sessionStorage
  }
}
```

## JS ↔ ADVPL bidirectional channel

- App side: create `advpltojs.js` under `assets/preload` (receives ADVPL instructions); send with `ProJsToAdvplService` / `twebchannel.jsToAdvpl('type', 'content')`.
- ADVPL side — the source that called FwCallApp must contain (CANNOT be TLPP — needs a Static Function):
```advpl
Static Function JsToAdvpl(oWebChannel, cType, cContent)
    If cType == 'getParam'
        oWebChannel:AdvPLToJS('setParam', SuperGetMv(cContent))
    EndIf
Return
```
- Low level: `TWebChannel():New()` + `oWebChannel:bJsToAdvpl := {|self,type,content| ...}` + `TWebEngine():New(oDlg,...,oWebChannel:nPort)`; ADVPL→JS via `oWebChannel:advplToJs(type, content)`. Observables supported (buildObservable).

## Framework generic services the lib consumes
`BasicProtheusServices` / `fwformstructview` (SX3 structure via REST), `GenericLookupService` (standard F3 lookup via REST), `FWAdapterBaseV2` (classic REST adapter). Dynamic screens = minimum 2 requests: metadata + values.

## Legacy environments (lib < 20200214)
Params `MV_GCTPURL` (`http://host:http-port`) + `MV_BACKEND` (`http://host:rest-port/rest`) + `[HTTP] Path=<rootpath>\http-root`. Modern environments only need `App_Environment`.

## Reference example (best current one)
https://github.com/danilosalve/sample-protheus-lib-core — Angular 21 + PO-UI 21 + lib-core 21, standalone components + signals, plus `server/` with a complete TLPP REST backend and the packaged `.app`.
Docs: FwCallApp TDN page · "Apps no Protheus" (medium.com/totvsdevelopers/apps-no-protheus-10db4f47f9fc).
