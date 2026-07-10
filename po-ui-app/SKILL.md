---
name: po-ui-app
description: Builds and maintains Angular apps with PO-UI (TOTVS UI library), embedded in Protheus or standalone via REST. Use when creating/editing PO-UI or Angular frontends for Protheus, working with po-* components, po-page-dynamic templates, protheus-lib-core, FwCallApp apps, or wiring a frontend to Protheus REST APIs.
---

# PO-UI Application Development (Protheus-focused)

Angular + PO-UI (`@po-ui/ng-*`) apps for TOTVS Protheus. Backend counterpart: skill `protheus-api-poui`.

**Output language rule: all user-facing output — code comments, commit messages, UI texts, chat responses — in PT-BR. Identifiers in English. Skill/reference files are in English by design.**

## Execution mode — decide FIRST (changes setup, auth, build, licensing)

| | Embedded (FwCallApp) | Standalone (REST) |
|---|---|---|
| Opens from | Protheus menu (webapp/smartclient) | Browser, any host |
| Auth | Inherited (ERPTOKEN via protheus-lib-core interceptors) | OAuth2 `/api/oauth2/v1/token` + own interceptor |
| Server | Multi-Protocol Port (MPP) | Standard `[HTTPREST]` + CORS |
| Licenses | **None extra** (documented) | Consumes REST licenses |
| Deploy | zip → `.app` → resource in RPO (patch) | Any web host |
| Extra lib | `@totvs/protheus-lib-core` + `@totvs/po-theme` | none required |

Hybrid (same app, both modes) is supported: branch on `ProAppConfigService.insideProtheus()`. When the user hasn't specified the mode, ask — licensing and deploy differ materially. Details: [references/protheus-embedded.md](references/protheus-embedded.md) and [references/authentication.md](references/authentication.md).

## Project setup

```bash
npm i -g @angular/cli@<N>          # PO-UI major == Angular major (e.g. 21 ⇔ 21); Node 20.11+
ng new my-app --skip-install && cd my-app && npm install
ng add @po-ui/ng-components        # theme, providers, optional shell (toolbar+menu) — answer Y
ng add @po-ui/ng-templates         # dynamic pages, login, etc.
# embedded mode only:
npm i subsink && npm i @totvs/protheus-lib-core@<same major>   # v19 needs --force
```

Interceptors need `provideHttpClient(withInterceptorsFromDi())` + animations provider. Never hardcode the API host for embedded apps — use `assets/data/appconfig.json` with `"api_baseUrl": "/"` (FwCallApp rewrites it at runtime; same build runs on every environment).

## Development rules

1. **Prefer dynamic templates over hand-built pages** for standard CRUD: `po-page-dynamic-table/edit/detail` work from route data + the standard REST contract with near-zero code. Only drop to `po-page-list/edit/detail` + `po-table` when the layout is genuinely non-standard. See [references/dynamic-templates.md](references/dynamic-templates.md).
2. **The REST contract is the integration point.** Everything data-driven expects `{items, hasNext}`, `page/pageSize/order/search/filter`, TOTVS error format `{code, message, detailedMessage}`. Full spec: [references/api-contract.md](references/api-contract.md). If the backend doesn't follow it, fix the backend (skill `protheus-api-poui`), don't work around it in the front.
3. **Pick components from the catalog first**: [references/components.md](references/components.md) — don't rebuild what po-table/po-lookup/po-notification already do. Notifications via `PoNotificationService`; dialogs via `PoDialogService`; let `po-http-interceptor` surface `_messages`/errors automatically.
4. **Modern Angular style** (upstream PO-UI rule for new code): standalone components, `@if/@for/@switch`, signals, function-based inputs, typed reactive forms. Match existing style in legacy projects.
5. **Structure**: feature folders with lazy routes; shared/ for services, models, i18n literals (`PoI18nModule` — literals pt/en/es/ru); one service per entity encapsulating the REST calls.
6. **Icons/themes**: v21+ uses Animalia icons (`an an-*`); `po-icon-*` classes are gone. Theming via `PoThemeService` (dark mode, AA/AAA, density). Embedded apps use `@totvs/po-theme`.
7. **Version discipline**: Angular and PO-UI majors must match. protheus-lib-core only publishes majors 14/15/17/19/21 — there is NO lib-core for Angular/PO-UI 16/18/20; embedded apps on those majors must stay on the previous published major (e.g. Angular 19 + lib-core 19, which receives backports). Upgrades: `ng update @angular/cli@N @angular/core@N --force` then `ng update @po-ui/ng-components --allow-dirty --force`. Check the CHANGELOG (live sources) before any upgrade.

## Verification

- `ng build` must pass; for embedded apps also validate the packaging checklist in protheus-embedded.md (index.html, base href, lowercase folder, no CDN, appconfig.json) before generating the `.app`.
- Test data-driven pages against a real contract early — po-sample-api (https://po-sample-api.fly.dev/api/) is a live conformant backend for smoke tests.
- With the app running (`ng serve`), use the `chrome-devtools` MCP to inspect the page, console errors and failed requests instead of relying on build success alone.

## Live sources (consult instead of guessing)

- Component props/API: MCP server `po-ui` (official PO-UI docs MCP — search components/guides; use it BEFORE guessing any p-* property) or Context7 (`/po-ui/po-angular`); portal per component: `https://po-ui.io/documentation/<selector>`
- Angular questions (CLI, best practices, angular.dev docs, workspace info): MCP server `angular`
- Visual verification of running apps (console, network, DOM, screenshots on localhost): MCP server `chrome-devtools` — prefer checking the rendered result over assuming the code works
- Breaking changes / new components / version questions: https://github.com/po-ui/po-angular/blob/master/CHANGELOG.md
- Guides source (the portal is a SPA — fetch these instead): https://github.com/po-ui/po-angular/tree/master/docs/guides
- Full working example (embedded, Angular 21 + TLPP backend): https://github.com/danilosalve/sample-protheus-lib-core
- protheus-lib-core docs: https://tdn.totvs.com.br/display/framework/Protheus-lib-core · FwCallApp: TDN "FwCallApp - Abrindo aplicativos Web no Protheus"
- TOTVS API standard: https://github.com/totvs/ttalk-standard-message (totvsApiTypesBase.json)
