# SX6 — Parameters (MV_*)

SX6 is the dictionary of named runtime parameters — the `MV_*` family. Almost every configurable behaviour in Protheus reads from SX6: tax codes, default series, currency rounding, integration endpoints. SX6 is read constantly; the platform aggressively caches it.

## SX6 attributes

| Field | Type | Purpose |
| --- | --- | --- |
| `X6_FIL` | Char(2) | Branch the row belongs to. Blank = applies to all branches. |
| `X6_VAR` | Char(10) | Parameter name. Must be unique within the (branch + name) pair. **Key**. |
| `X6_TIPO` | Char(1) | `C` Character, `N` Numeric, `D` Date, `L` Logical. |
| `X6_DESCRIC`, `X6_DSCSPA`, `X6_DSCENG` | Char(50) | First-segment description in PT/ES/EN. |
| `X6_DESC1`, `X6_DSCSPA1`, `X6_DSCENG1` | Char(50) | Second-segment description. |
| `X6_DESC2`, `X6_DSCSPA2`, `X6_DSCENG2` | Char(50) | Third-segment description. |
| `X6_CONTEUD` | Char(250) | Current value in PT. The actual runtime value of the parameter. |
| `X6_CONTSPA` | Char(250) | Value in ES. |
| `X6_CONTENG` | Char(250) | Value in EN. |
| `X6_PRIORI` | Char(1) | `S` = system priority (cannot be modified by user), `U` = user. |
| `X6_PROPRI` | Char(1) | `S` = TOTVS-created, `U` = customer-created. |
| `X6_PYME` | Char(1) | Used by Protheus Série 3. |
| `X6_VALID` | Char(160) | Validation expression evaluated at parameter edit time in the Configurador. |
| `X6_DEFPOR`, `X6_DEFSPA`, `X6_DEFENG` | Char(250) | The **default** TOTVS-shipped value. Populated only for TOTVS-owned parameters. Used by migrators to detect whether the customer changed the value. |
| `X6_EXPDEST` | Char | Copy-content flag (from release 12.1.025). |
| `X6_ACTIVE` | Char | `1` / `2` — whether the parameter is currently used by standard product routines. |
| `X6_INIT` | — | Not used. |

The description is split into three 50-char columns so the Configurador can render it on three lines without truncating.

## Naming — `MV_YYZZZZZ`

The TOTVS convention is:

```
MV_ + YY + ZZZZZ
```

| Segment | Meaning |
| --- | --- |
| `MV_` | Marker for "parameter" |
| `YY` | Two-letter module / origin code |
| `ZZZZZ` | Free name |

`X6_VAR` is `Char(10)`, so the body after `MV_` is 7 chars maximum.

Customer prefixes:

| Prefix | Origin |
| --- | --- |
| `MV_ES*` | Customer-owned ("Especifico"). Most common for site customisations. |
| `MV_FS*` | Fábrica de Software TOTVS. |
| `MV_*` | TOTVS standard (don't use this for new customer parameters). |

Examples:

```
MV_ESBLQCR  -- customer parameter: "blocks credit when ..."
MV_ESCRDLIM -- customer parameter: credit limit default
MV_FSAPIURL -- factory-built parameter: API endpoint
```

## Branch scoping (`X6_FIL`)

The same `X6_VAR` can have multiple rows, each with a different `X6_FIL`:

```
X6_FIL  X6_VAR        X6_CONTEUD
""      MV_BLQCR      "N"          (default for all branches)
"01"    MV_BLQCR      "S"          (override for branch 01)
"02"    MV_BLQCR      "N"          (explicit, same as default)
```

`SuperGetMV("MV_BLQCR", .F., "N")` first tries the current branch then falls back to the blank-branch row, then to the third-arg default. This is the recommended reader.

## Reading parameters

| Function | Behaviour |
| --- | --- |
| `GetMV(cParam, lUseDef, uDefault)` | Reads SX6. If the row doesn't exist and `lUseDef = .F.`, returns the default in the third arg without writing anything. |
| `SuperGetMV(cParam, lUseDef, uDefault, cBranch)` | Same as GetMV but cached in memory after the first read. **Preferred**. Honours `cBranch` if passed. |
| `PutMV(cParam, uValue)` | Writes a value to SX6. Use only in migrators. Never use in production fontes — it mutates the dictionary. |

**Always pass a default** to `SuperGetMV`. The parameter may not exist yet on the customer's environment when your fonte runs the first time after deploy. A missing default causes a runtime error.

```advpl
// Right
Local cBlqCR := SuperGetMV("MV_ESBLQCR", .F., "N")

// Wrong — crashes if the parameter doesn't exist
Local cBlqCR := SuperGetMV("MV_ESBLQCR")
```

## Cache

`SuperGetMV` caches per session. A parameter changed in the Configurador will not be picked up by a live session until:

- The user reconnects, or
- The cache is invalidated programmatically with `FwClearMVCache()` (newer LIBs).

If your routine sets a parameter via the Configurador and reads it in the same session, expect stale data. Force a re-read with `GetMV` (uncached) in that narrow case.

## Parameter-creation workflow

For `MV_ESCRDLIM` (numeric credit limit default):

1. In Configurador → Ambiente → Cadastros → Parâmetros (CFGX031).
2. Click **Incluir**.
3. Fill:
   - Filial: blank (applies to all) or the specific branch.
   - X6_VAR: `MV_ESCRDLIM`.
   - X6_TIPO: `N`.
   - Descrição (3 lines): `Limite de credito default`, `por cliente quando A1_LC = 0`, `no cadastro CRM`.
   - Conteúdo: `1000.00`.
   - Propriedade: Usuário (auto).
   - Tamanho: tipicamente o tamanho do `X6_CONTEUD`. Para numéricos, é convenção armazenar com a precisão necessária.
4. Confirmar.

The parameter is now readable via `SuperGetMV("MV_ESCRDLIM", .F., 1000.00)`.

**Document the parameter** in `.claude/plans/<slug>/pre-producao.md` — the deploy is manual via Configurador.

## Type handling — careful with `X6_CONTEUD`

`X6_CONTEUD` is always stored as a string. The runtime conversion is based on `X6_TIPO`:

- `C` — kept as string.
- `N` — converted via `Val()`.
- `L` — must be the literal `.T.` or `.F.`.
- `D` — must be the literal `ctod("DD/MM/YYYY")` expression.

For dates, store as the string expression (`CTOD("01/01/2026")`) and let the reader evaluate it. Storing `20260101` (DTOS format) does not work — the engine doesn't know the type to parse it.

## What survives a TOTVS upgrade (UPDDISTR)

For SX6, UPDDISTR has a very specific rule (see [upddistr-rules.md](upddistr-rules.md)):

- `X6_CONTEUD` (the actual value): **never overwritten**. Customer values are preserved across upgrades. This is intentional — the customer's configuration is the customer's choice.
- Descriptions (`X6_DESCRIC`, etc.): always overwritten by the new TOTVS values.
- `X6_PROPRI`, `X6_PYME`, `X6_DEFPOR/SPA/ENG`: never overwritten.
- `X6_VALID`: from the 2020-11-23 LIB, always overwritten.

This means a custom parameter created on the customer's environment is fully owned by the customer. A standard `MV_*` parameter the customer changed will keep its changed value forever (until manually reset to `X6_DEFPOR`).

## When NOT to use SX6

SX6 is global-ish (branch-scoped at most). It is not a per-user setting, not a per-document setting, not a per-row setting.

- Per-user preference → `AP5USERDICT` / TOTVS Identity.
- Per-branch operational state → SX6 is fine.
- Per-document toggle → field on the document table.
- Frequently-changing value (every minute) → don't. SX6 reads are cached; writes invalidate caches across the cluster. Move to a regular table.

## Useful functions

| Function | Purpose |
| --- | --- |
| `GetMV(cParam, lUseDef, uDefault)` | Uncached read. |
| `SuperGetMV(cParam, lUseDef, uDefault, cBranch)` | Cached read. Preferred. |
| `PutMV(cParam, uValue)` | Migrator-only write. |
| `X6Descric()` | Description (line 1) of the positioned SX6 row. |
| `X6Desc1()`, `X6Desc2()` | Description lines 2, 3. |
| `X6Conteud()` | Value of the positioned row, in the current language. |
| `FwClearMVCache()` | Clears the SuperGetMV cache (newer LIBs). |
