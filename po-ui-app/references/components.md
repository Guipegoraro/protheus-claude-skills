# PO-UI Component Catalog (@po-ui/ng-components)

Quick map of what exists so you pick the right component instead of hand-building. For full props of any component, fetch `https://po-ui.io/documentation/<selector>` via Context7/po-ui MCP or read the JSDoc in github.com/po-ui/po-angular.

## Pages (basic, code-driven — for non-standard pages; prefer dynamic templates for standard CRUD)
- `po-page-default` — generic container: title, actions, breadcrumb
- `po-page-list` — list page with quick/advanced filter + disclaimers (you wire the data)
- `po-page-edit` — Save / Save&New / Cancel actions
- `po-page-detail` — Back / Edit / Remove actions
- `po-page-slide` — sliding side panel
- Generate: `ng generate @po-ui/ng-components:po-page-list|po-page-default|po-page-edit|po-page-detail`

## Form fields (po-field)
`po-input`, `po-number`, `po-decimal`, `po-email`, `po-password`, `po-url`, `po-textarea`, `po-select`, `po-combo` (URL/service support), `po-multiselect` (idem), `po-lookup` (REST modal search — see dynamic-templates.md), `po-datepicker`, `po-datepicker-range`, `po-datetimepicker`, `po-timepicker`, `po-checkbox`, `po-checkbox-group`, `po-radio`, `po-radio-group`, `po-switch`, `po-upload` (REST file upload), `po-rich-text`, `po-login`, `po-clean`, `po-search-ai` (experimental AI search).

## Data display
- `po-table` — THE grid: sortable (`p-sort`, `p-sort-by` event), single/multi selection, row actions, column manager, "load more" (`p-show-more` + `p-has-next`), infinite scroll, cell/column/row templates. Column types: string, number, currency, date, dateTime, time, link, label, subtitle, icon, boolean, detail, cellTemplate. Does NOT call APIs itself — feed `p-items` from a `{items, hasNext}` fetch.
- `po-list-view`, `po-tree-view`, `po-grid` (editable grid, used by dynamic-edit detail), `po-chart` (area/bar/column/line/pie/donut/radar/gauge — echarts-based), `po-gauge` (deprecated v19+), `po-info`, `po-tag`, `po-badge`, `po-avatar`, `po-image`, `po-icon`, `po-progress`, `po-skeleton` (loading placeholder), `po-widget`, `po-container`, `po-divider`.

## Navigation / structure
`po-menu`, `po-menu-panel`, `po-navbar` (DEPRECATED v20.1+), `po-toolbar`, `po-breadcrumb`, `po-tabs`, `po-context-tabs`, `po-stepper`, `po-header`, `po-slide` (carousel). App shell pattern: `po-wrapper > po-toolbar + po-menu + router-outlet`.

## Overlay / feedback
`po-modal`, `po-dialog` (PoDialogService: alert/confirm), `po-popover`, `po-popup`, `po-context-menu`, `po-dropdown`, `po-toaster` (via PoNotificationService), `po-loading` / `po-loading-overlay`, `po-notification` (PoNotificationService: success/warning/error/information), `po-helper` (contextual help — new standard over help tooltips).

## Filters
`po-disclaimer`, `po-disclaimer-group`, `po-filter-chip` (21.16+), `po-search`, `po-listbox`.

## Services
- `PoNotificationService` — toasts (success/warning/error/information)
- `PoDialogService` — alert/confirm dialogs
- `PoI18nService` + `PoLanguageService` — i18n with contexts (built-in literals: pt, en, es, ru)
- `PoThemeService` — themes, dark mode, accessibility AA/AAA, density (`PoDensityMode`); v19+ preferred over raw CSS token overrides
- `PoDateService`, `PoColorService`, `PoMediaQueryService`, `PoUserGuideService` (21.18+)

## HTTP interceptors
- `PoHttpInterceptorService` — auto-notifications from responses (`_messages` on 2xx, error object on 4xx/5xx); control headers `X-PO-No-Message`, `X-PO-No-Error`
- `PoHttpRequestInterceptorService` — pending-request counter (`getCountPendingRequests()`); headers `X-PO-Screen-Lock`, `X-PO-No-Count-Pending-Requests`
- Require `provideHttpClient(withInterceptorsFromDi())` + animations provider.

## Other packages
- `@po-ui/ng-code-editor` — Monaco-based `po-code-editor`
- `@po-ui/ng-storage` — `PoStorageService` (localforage + lokijs)
- `@po-ui/ng-sync` — offline-first sync (PoSyncService, PoSyncSchema, event queue; Capacitor Network). Guide: po-ui.io/guides/sync-get-started; contract in api-contract.md §8
- `@po-ui/style` — theme CSS (`po-theme-default.min.css`), grid system (po-row, po-sm/md/lg/xl-1..12), spacing, typography
- `@po-ui/theme-cli` — build/publish custom themes (`po-theme new` / `po-theme build`)
- `@po-ui/mcp` — official docs MCP server (`npx @po-ui/mcp`)

## Version rules (critical when scaffolding)
- PO-UI major == Angular major (21.x ⇔ Angular 21). Node 20.11+.
- `ng update @po-ui/ng-components --allow-dirty --force` migrates all @po-ui packages together (packageGroup).
- Icons since v21: Animalia icons `an an-<name>` (`po-icon po-icon-*` classes REMOVED in v21; `ph ph-*` was v19–20 era). Design system: https://doc.animaliads.io/
- New-code style enforced upstream (good baseline): standalone components, `@if/@for/@switch` (never *ngIf/*ngFor/CommonModule), signals, function-based inputs `input<string>('', {alias: 'p-label'})`, typed reactive forms.
- Angular 19+ builder issue: if `@angular/build:dev-server` missing → `npm i -D @angular/build` and fix angular.json builders.
