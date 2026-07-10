# PO-UI Page Templates (@po-ui/ng-templates)

Ready-made full-page templates. Prefer these over hand-built pages for standard CRUD — they consume the REST contract (see api-contract.md) with near-zero code. All dynamic pages send `X-PO-Screen-Lock: true` automatically.

Generate with: `ng generate @po-ui/ng-templates:<name>` (po-page-dynamic-table, po-page-dynamic-edit, po-page-dynamic-detail, po-page-dynamic-search, po-page-job-scheduler, po-page-login, po-page-change-password, po-page-blocked-user).

## po-page-dynamic-table — list page

Route-only usage (zero component code):

```typescript
{ path: 'people', component: PoPageDynamicTableComponent,
  data: {
    serviceApi: '/api/myapp/v1/people',
    serviceMetadataApi: '/api/myapp/v1/metadata',   // optional, GET
    serviceLoadApi: '/api/myapp/v1/load-metadata'   // optional, POST customization
  } }
```

Template usage:

```html
<po-page-dynamic-table
  p-service-api="/api/myapp/v1/people"
  [p-fields]="fields"
  [p-actions]="{ new: 'new', edit: 'edit/:id', detail: 'view/:id', remove: true, removeAll: true, duplicate: 'new' }">
</po-page-dynamic-table>
```

- `p-fields`: array of `{ property, key, label, filter, visible, duplicate, ... }`. `key: true` marks the primary key (used to build `/{id}` routes and DELETE).
- `p-actions` hooks: `beforeNew/beforeEdit/beforeRemove/beforeRemoveAll/beforeDetail/beforeDuplicate` (string endpoint or function).
- Other inputs: `p-page-custom-actions`, `p-table-custom-actions`, `p-load` (endpoint POST or fn → PoPageDynamicTableOptions), `p-keep-filters`, `p-concat-filters`, `p-infinite-scroll`, `p-hide-columns-manager`, `p-auto-router`, `p-quick-search-width`.
- REST calls it makes: `GET {api}?page=1&pageSize=10[&search=][&field=value][&order=]`; `DELETE {api}/{keys}`; `DELETE {api}` (body = array) for removeAll; `GET {api}/metadata?type=list&version={v}`.

## po-page-dynamic-edit — create/edit page

- Route with `:id` → loads `GET {api}/{id}`, saves with `PUT {api}/{id}`. Route without id → `POST {api}`.
- `p-actions`: `{ save: '/', saveNew: 'new', cancel, beforeSave, beforeSaveNew, beforeCancel }`.
- Uses po-dynamic-form internally; detail grids via po-grid. Metadata: `GET {api}/metadata?type=edit`.
- Built-in success/error literals in pt/en/es/ru.

## po-page-dynamic-detail — read-only view

- Route `people/:id`, same data keys. Loads `GET {api}/{id}`; actions back/edit/remove (`DELETE {api}/{id}` with confirm dialog); hooks beforeBack/beforeEdit/beforeRemove. Metadata `type=detail`.

## po-page-dynamic-search — search shell (no own REST calls)

- Renders quick search + advanced search (PoDynamicFormField) + disclaimers; YOU implement the API call in the events.
- Events: `p-quick-search` (string), `p-advanced-search` (filters object), `p-change-disclaimers`. Quick-search disclaimer uses property `search`.
- Inputs: `p-filters`, `p-keep-filters`, `p-concat-filters`, `p-visible-fixed-filters`, `p-hide-close-disclaimers`.

## po-dynamic-form / po-dynamic-view (components, not pages)

- `po-dynamic-form`: runtime form from `p-fields: PoDynamicFormField[]` ({property, type, label, required, options, optionsService, mask, gridColumns, help, ...}); `p-value` = model; output `p-form` (NgForm).
  - `p-load` (init) and `p-validate` (on field change) accept endpoint string or function: POST `{ value, field }` → `{ value, fields, focus }` to mutate the form dynamically.
  - `optionsService` consumes a standard contract endpoint.
- `po-dynamic-view`: read-only render from fields/value; `p-load` = URL or function.
- Dynamic components make AT LEAST 2 requests: metadata + values (TOTVS cross-product pattern, also used in Datasul).

## po-page-login — authentication page

- `p-authentication-url` + `p-authentication-type`:
  - `'Basic'` (default): `POST url`, header `Authorization: Basic b64(login:password)`, body `{rememberUser}`.
  - `'Bearer'`: `POST url`, body `{ login, password: b64(password), rememberUser }`.
- 200 `{user}` → stored in sessionStorage, redirect `/`. 400/401 → standard error object + `maxAttemptsRemaining`, `loginWarnings[]`, `passwordWarnings[]`; `maxAttemptsRemaining=0` + `p-blocked-url` → redirects to po-page-blocked-user.
- No `p-authentication-url`? Handle `p-login-submit` event yourself (this is the path for Protheus OAuth2 — see authentication.md).
- Companions: po-modal-password-recovery (`p-url-recovery` automates), po-page-change-password (`p-url-new-password` automates POST), po-page-blocked-user (configurable via route data; requires mapping `node_modules/@po-ui/style/images` in angular.json assets).

## po-page-job-scheduler — schedule backend processes

- Stepper: Execution → Parameters → Summary. Inputs: `p-service-api`, `p-parameters` (PoDynamicFormField[] — if given, skips process lookup), custom templates via PoJobSchedulerParametersTemplate / SummaryTemplate directives.
- REST: `GET {api}/processes[?search=]` → `{items:[{processID, description}]}`; `GET {api}/processes/{id}/parameters` → `{items: PoDynamicFormField[]}`; create `POST {api}` with `{ processID, firstExecution: ISO-8601, recurrent, daily|weekly|monthly, rangeExecutions?, executionParameter? }`; edit via `GET/PUT {api}/{id}`. Availability probe: `HEAD {api}/processes` (with X-PO-No-Error).

## po-lookup (field, heavily used in Protheus F3-style searches)

- `p-filter-service`: URL or object implementing PoLookupFilter. `p-field-value` (value column), `p-field-label` (label/filter column), `p-columns` (PoLookupColumn[]), `p-filter-params`, `p-advanced-filters`, `p-multiple`.
- REST (URL mode): modal filter `GET url?page=1&pageSize=20&filter=Peter` (param is `filter`, not `search`); sort `&order=-name`; initial value `GET url/{value}`; multiple `GET url?{fieldValue}=1,2`. Response = standard `{items, hasNext}`.
- Typing a value + TAB does an exact fetch by key.
