---
name: protheus-consulta-padrao
description: Designs, audits, and wires Protheus Consulta Padrão (F3 lookup) entries in the SXB dictionary. Covers the four query categories (Padrão, Específica, Usuário, Grupo) and the nine SXB record types — XB_TIPO 1 (table), 2 (indexes), 3 (insert/view buttons), 4 (visible fields per index), 5 (return values), 6 (filter), 7 (upper/lower bounds), 8 (analytical button), 9 (source override). Also covers how an SX3 field gets a lookup via X3_F3, programmatic invocation with ConPad1, and MVC integration with FWLookUp. Use when the user mentions consulta padrão, F3, SXB, XB_TIPO, XB_ALIAS, lookup, lupa de pesquisa, GenericLookupService, X3_F3, or when designing/reviewing a new lookup for a custom field or table.
---

# Protheus Consulta Padrão (SXB / F3)

A **Consulta Padrão** (a.k.a. Standard Lookup, F3) is a reusable lookup screen defined in the SXB dictionary. It powers the magnifying-glass button next to a field and the F3 key.

The SXB is unlike other dictionaries: **one query is a set of records**, not a single row. Each record's role is determined by `XB_TIPO`.

## Categories

There are four query categories. Pick the right one before writing anything:

| Category | When to use | Type 1 key (`XB_COLUNA`) | Where data comes from |
| --- | --- | --- | --- |
| **Padrão** | Lookup over a regular Protheus table (most common) | `DB` | Any table registered in SX2 |
| **Específica** | Custom screen drawn by an AdvPL function | `RE` | Whatever the function (`XB_TIPO`=2) returns into `VAR_IXB` |
| **Usuário** | Pick one user | `US` | System user table |
| **Grupo de Usuários** | Pick a user group | `GR` | System group table |

Anything table-shaped uses **Padrão**. A wizard, a tree, a file picker, anything not table-shaped uses **Específica**.

See [record-types.md](record-types.md) for the field-level shape of every `XB_TIPO`.

## Workflow

When the user asks to design or modify a Consulta Padrão, follow this checklist:

```
- [ ] 1. Confirm category (Padrão / Específica / Usuário / Grupo)
- [ ] 2. Pick an XB_ALIAS key (the consulta code) — see naming below
- [ ] 3. List record types that will be created (always 1, 2, 4, 5; the rest are optional)
- [ ] 4. For type 2: verify the index exists in SIX with the desired key
- [ ] 5. For type 5: confirm the return field is contained in the type-2 index
- [ ] 6. Decide who creates the rows: Configurador (always preferred) vs source (only for runtime/temporary cases)
- [ ] 7. Document in .claude/plans/<slug>/pre-producao.md **step-by-step in the Configurador wizard format** (see below)
- [ ] 8. Wire it to the SX3 field via X3_F3 (also via Configurador)
```

## Documenting in pre-producao.md (load-bearing)

The consulta padrão entry in `.claude/plans/<slug>/pre-producao.md` is what the consultor reads on deploy day to actually create the SXB in the Configurador. **Don't just dump the SXB table — that helps no one who hasn't worked in the Configurador wizard before.** Write it as a wizard walkthrough.

Required sections (in this order):

1. **Visão geral**: one paragraph saying what the consulta does, **from the operator's perspective** (what they see when they press F3, what filters apply, why).
2. **Caminho no Configurador**: numbered list with the exact menu path (`SIGACFG → Base de Dados → Dicionário → Bases de Dados → Consultas Padrão → Incluir`) and the fact that the wizard has N telas.
3. **Tela 1 — Dados básicos**: table mapping wizard fields (Alias, Tipo, Descrição PT/ES/EN) to the values to type.
4. **Tela 2 — Tabela da consulta**: which SX2 table to select.
5. **Tela 3 — Índice(s)**: which índice from the SIX to add. **Always cite the index key explicitly** (`BE_FILIAL+BE_LOCAL+BE_LOCALIZ+...`) so the consultor can pick the right one even if the order is customised. Include the sub-tela for adding visible columns (each field, its order, and the visible title — table format).
6. **Tela 4 — Retorno da consulta**: which field is written back to the calling form. Spell out the rule that the return field must live in the chosen index (regra crítica).
7. **Tela 5 — Filtro (tipo 6)**: the exact filter expression to type, **plus a beginner-friendly explanation of each piece** (`@` push-down, `M->CAMPO` memory variable, what the SQL fragment becomes at runtime).
8. **Outras configurações (deixar como default)**: explicit list of tipos 3, 7, 8, 9 left blank — prevents "should I set this?" doubt.
9. **Como amarrar ao campo SX3**: separate procedure to set `X3_F3` on the host field after the consulta is created. Often forgotten.
10. **Plano B**: alternative filter syntax (no `@`) for environments where push-down doesn't work, with explicit instructions to switch the doc and kanban after the test.
11. **Resumo SXB (referência técnica)**: only at the END, the raw SXB rows table for the technically-inclined consultor who wants to audit later. Mark it explicitly as "the Configurador generates these — don't type them directly".

The consultor reading this doc may not be the developer who designed the consulta. Write so a new person on the team can apply it without having to ask — the 11-section structure above is the template.

If the user asks for the consulta and you're not generating `pre-producao.md` at the same time, **remind them** that the implementation hand-off needs the doc — half-finished consultas trip on deploy day.

## Hard rules

- **Never** create SXB rows via source in production. `RecLock("SXB",.T.)` + `PutSXB` belong to migrators or one-off util scripts, **not** customisation fontes. Dictionary mutations from a source file mix with business logic, leave the env inconsistent if they fail mid-way, and require a server restart to take effect cleanly. Use the **Configurador** module.
- **UPDDISTR replaces the whole consulta**: it deletes every row of that `XB_ALIAS` and reinserts the new ones. There is no partial update. Always ship the *complete* set of records for any consulta you change, never just the diff.
- **Type-5 return must come from the type-2 index.** If type 2 says the index is "01" (e.g. `A1_FILIAL+A1_COD+A1_LOJA`) and type 5 returns `A1_CGC`, the engine cannot position. The lookup will appear to work but break on selection.
- **Returns fill subsequent fields in the calling form** in the order declared (`XB_SEQ`). A consulta that returns code + store fills the next two fields in the GetDados/MsGetDB. The host form must be laid out to receive them in that order.
- **F3 wiring lives in `SX3.X3_F3`**, not in the consulta itself. Setting `X3_F3 = "SA1"` on field `C5_CLIENTE` is what makes the lupa appear and pressing F3 open the consulta with `XB_ALIAS = "SA1"`.

## Best practices

- **Reuse before you create.** Search SXB for an existing query against the same table and index. Most tables (SA1, SB1, SF4, etc.) already have one or several.
- **Show concise columns** in type 4. A user picking a customer needs code + name; CNPJ and registration date go to optional indexes. Wide grids slow the modal and force the user to scroll.
- **Filter at the source (type 6) rather than client-side after selection.** Two flavors:
  - **ADVPL expression (default, recommended for filters with `M->CAMPO`)**: e.g. `SBE->BE_LOCAL == M->CP_ZARDEST`. Evaluated row by row but supports memory variables seamlessly. This is the form used by virtually every dynamic filter in the standard TOTVS dictionary (`AKE->AKE_ORCAME==M->AKR_ORCAME`, `ADY->ADY_OPORTU == M->AAT_OPORTU`, etc).
  - **`@` SQL push-down (v12+, only for CONSTANTS)**: e.g. `@A1_COD IN ('000001','000002')` or `@G3B_TIPO = '1'`. Faster on large tables, but **does not support runtime variable substitution** — strings like `@BE_LOCAL = '"+M->CAMPO+"'` are pushed as **literal text** to the WHERE clause, producing empty results. To get push-down with a dynamic value, use the macro form `#U_MyFilterFn()` where the function returns the fully-built SQL string (e.g. `Return "@BE_LOCAL = 'XX'"`).
  - **Default to the ADVPL expression** unless you measured a performance problem with it — premature optimization with `#` macros costs readability.
- **Use registro tipo 9** to redirect insert/view to a custom routine instead of stuffing `#` markers into type 3's `XB_CONTEM`. Tipo 9 is the modern, supported path; the `#` syntax is legacy.
- **Avoid `Posicione()` and `IF()` in type 5** if you need the consulta to work with `GenericLookupService` (Smart View, the REST lookup API, web parameters). That service only supports DB queries whose return is a plain SX3 field, a concatenation of SX3 fields, or `Posicione()`. Functions, `IF`/`IIF`, `&`, `@`, `#` are silently skipped.
- **Mind the column widths.** `XB_DESCRI` is short — long labels truncate silently. Pick short, language-neutral titles or rely on `XB_DESCSPA` and `XB_DESCENG` for localisation.

## XB_ALIAS naming

`XB_ALIAS` is a 6-char code, not a table name (even though it often coincides with one). Conventions:

- **Default consulta over a table**: use the table alias (`SA1`, `SB1`, `SF4`). Only one per table can exist with this exact alias.
- **Alternate consulta over the same table**: prefix or suffix with a short discriminator. Common style: `SA1A`, `SA1CRM`, `ZSA1`. Pick something that won't clash with TOTVS standard codes.
- **Custom (Z-namespace) consulta**: prefix with `Z` to make it visibly customer-owned (`ZCONS1`, `ZSA1FX`).
- Custom consultas should not start with TOTVS prefixes like `MV`, `FW`, `TAF`.

## Source of truth

When you need to verify the current state of a consulta on the **product** (standard TOTVS dictionary), use the `advpl-tlpp-mcp-docs` MCP:

- `execute-sql` against `SXBT10` to see the rows of an existing consulta.
- `language-system-docs-search` for the official TDN documentation of any XB_TIPO.
- `code-search` to find how a `ConPad1` / `FWLookUp` is invoked in standard Protheus sources.

This MCP exposes the **reference TOTVS base**, not the customer's environment. Customer-side state (which consultas they actually have, with their customisations) must come from a customer-side query (`/genericquery`) or the user.

## Detailed references

- **[record-types.md](record-types.md)** — every `XB_TIPO` field-by-field, with examples for all four categories.
- **[invocation.md](invocation.md)** — how `X3_F3` wires a field, `ConPad1` signature for manual invocation, `FWLookUp` in MVC views.
- **[examples.md](examples.md)** — concrete consultas: standard table lookup, filtered lookup, specific-function lookup, file picker.
- **[anti-patterns.md](anti-patterns.md)** — pitfalls collected from TDN release notes and field experience.
