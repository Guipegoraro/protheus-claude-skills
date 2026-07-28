---
name: protheus-configurador-dicionario
description: Creates and audits Protheus data dictionary entries via the Configurador module — tables (SX2), fields (SX3 + SXG groups), indexes (SIX), and parameters (SX6). Covers customer namespaces (SZ* / Z?? for tables, MV_ / customer prefixes for parameters), every X2_/X3_/X6_/SIX attribute, the Configurador workflow (Base de Dados → Dicionário → Bases de Dados → Atualizar base de dados in exclusive mode), UPDDISTR/migrador behavior per dictionary, X3_USADO/X3_RESERV/X3_OBRIGAT binary handling, virtual vs real fields, and migration safety. Use when the user mentions criar campo, criar tabela, criar parâmetro, dicionário de dados, Configurador, SIGACFG, SX2, SX3, SX6, SIX, SXG, X3_USADO, MV_, GetMV, customização de dicionário, atualizar base de dados, or when planning/auditing a new field/table/index/parameter for a Protheus customisation.
---

# Protheus Data Dictionary via Configurador

A Protheus customisation almost always needs new tables, fields, indexes, or parameters. These live in the **data dictionary** (SX2, SX3, SIX, SX6, SXG, SX7, …). The data dictionary is managed exclusively through the **Configurador** module (SIGACFG). Source-level mutations are forbidden in production.

The five dictionaries this skill covers:

| Dictionary | Purpose | Detailed reference |
| --- | --- | --- |
| **SX2** | Table registry (alias, file name, share mode, primary key, owning module) | [tables.md](tables.md) |
| **SX3** | Field definitions for each table (type, size, picture, validations, when, F3, virtual/real) | [fields.md](fields.md) |
| **SIX** | Index definitions per table (key, order, nickname, search visibility) | [indexes.md](indexes.md) |
| **SX6** | System parameters (MV_*) — single source of truth for runtime configuration | [parameters.md](parameters.md) |
| **SXG** | Field groups — keep the same conceptual field consistent across tables | [fields.md](fields.md) |

Also touched: SX7 (triggers) — see [fields.md](fields.md). SX1 (perguntas), SX5 (tabelas genéricas), SXA (folders), SXB (consulta padrão) are out of scope here; SXB is covered by the `protheus-consulta-padrao` skill.

## Hard rules

These are non-negotiable. Flag any deviation in code review.

1. **All dictionary changes go through the Configurador.** Source-level `RecLock("SX3")` / `PutSX3` / `PutSX6` / `RecLock("SX2")` are forbidden in customisation fontes. They belong only to migrators that own the dictionary at upgrade time. Reasons: cache inconsistency, broken transactions, conflict with UPDDISTR.
2. **Customer-owned tables use the `Z??` or `SZ?` namespace only.** `Z?` for compact 3-char aliases (`ZA0`, `ZB1`), `SZ?` for legacy 3-char (`SZ0`, `SZ1`). Any other prefix risks collision with a future TOTVS release.
3. **Customer-owned parameters use `MV_*` with a customer-prefixed name** — typically `MV_ES*` (cliente) or `MV_FS*` (fábrica de software). Never reuse a TOTVS parameter name with different semantics.
4. **Document every dictionary change in `.claude/plans/<slug>/pre-producao.md`** before applying it. The deploy is manual via Configurador; the document is the deploy checklist. **Every value in it is copy-pasteable**: the literal, complete content the operator will paste into the Configurador screen — no placeholders, no ellipses, no prose mixed into value cells; long values (help de campo, expressions, combo lists) in their own fenced code blocks. See the template in [examples.md](examples.md).
5. **"Atualizar base de dados" requires exclusive mode** — no user can have the affected table open. Schedule the step for off-hours or block access before running.
6. **Never read `X3_USADO`, `X3_RESERV`, `X3_OBRIGAT` as raw strings.** They are binary in older versions, character in 12.1.7+, and the encoding is opaque. Use `X3Uso()`, `X3Reserv()`, `X3Obrigat()`, `X3Chave()`, `X3Alteravel()`. Direct `Bin2Str` / `SubStr` / `Alltrim` on these will break across versions.
7. **The size of a field with a `X3_GRPSXG` group is governed by the SXG group, not by `X3_TAMANHO`.** Changing the SX3 size when an SXG group exists does nothing; you must change the SXG instead.
8. **Custom fields on standard TOTVS tables stay under the table's prefix.** Adding `Z_MYFIELD` to SA1 is wrong; the field must be `A1_MYFLD` with `X3_PROPRI = 'U'`. The Configurador sets `X3_PROPRI = 'U'` automatically when a logged-in customer user creates a field.
9. **Every new field ships with its help (F1) text, written at spec time.** The field spec (chat tables, `pre-producao.md`) includes the full help text per field. The text is written for the end user and is self-contained — it must not depend on or reference the documentation used during development (ticket, PRD, plano, e-mails). See "Help de campo (F1)" in [fields.md](fields.md).

## Workflow checklist

When the user wants to design or modify a dictionary entry, walk through this:

```
- [ ] 1. Identify which dictionaries the change touches (SX2, SX3, SIX, SX6, SXG)
- [ ] 2. Pick the right namespace
        - Table: Z?? or SZ? (custom) OR existing TOTVS table (extension only)
        - Field on custom table: <prefix>_NAME using the table prefix
        - Field on TOTVS table: <prefix>_NAME with X3_PROPRI = 'U'
        - Parameter: MV_ES* (cliente) or MV_FS* (fábrica)
- [ ] 3. For new fields: assign SXG group if a sibling field exists (B1_COD-like cases)
- [ ] 4. For new fields: write the help (F1) text — self-contained, end-user language,
        no reference to dev documentation (fields.md → "Help de campo (F1)")
- [ ] 5. For new indexes: assign a NICKNAME so the order is stable across versions
- [ ] 6. Write each row to .claude/plans/<slug>/pre-producao.md with all attributes
        (fields include the help text)
- [ ] 7. In Configurador: Base de Dados → Dicionário → Bases de Dados → select table → Editar
- [ ] 8. Add the field/index/etc. via the corresponding sub-screen (fields: fill the help too)
- [ ] 9. Confirm at the table level, then "Atualizar base de dados" (exclusive mode)
- [ ] 10. Validate physically: SQL/APSDU shows the column with the expected DDL
```

## Configurador menu paths

Single most important screen:

```
Configurador (SIGACFG)
└── Base de Dados
    └── Dicionário
        └── Bases de Dados        [CFGX034 / Dicionário de Dados]
            ├── Tabelas            (SX2)
            ├── Campos             (SX3)
            ├── Índices            (SIX)
            ├── Gatilhos           (SX7)
            ├── Pastas             (SXA)
            ├── Grupo de Campos    (SXG)
            ├── Consultas Padrão   (SXB)
            └── [Atualizar Base de Dados]   ← creates/alters physical columns
```

Parameters live one level over:

```
Configurador
└── Ambiente
    └── Cadastros
        └── Parâmetros            [CFGX031 / SX6]
```

Also useful:

```
Configurador
└── Base de Dados
    └── Gestão de Ambientes
        └── Cadastro de Projetos   ← apply project (transactional dictionary deploy)
```

## Naming conventions

Memorise these. They keep the customisation future-proof.

- **Tables**:
  - Customer prefix: `Z<L><N>` (`ZA0`, `ZB1`, …) or `SZ<N>` (`SZ0` … `SZ9`). After SZ9, continue `SZA`–`SZZ`.
  - Avoid any TOTVS prefix (`SA`, `SB`, `SC`, `SD`, `SE`, `SF`, `SR`, `SY`, `MV` etc.).
  - Customer extensions of TOTVS tables don't get a new table; they get new fields on the existing one.
- **Fields**:
  - Tables starting with `S` drop the `S`: `SA1` → `A1_…`, `SB1` → `B1_…`, `SF4` → `F4_…`.
  - Tables not starting with `S` keep the full prefix: `Z01` → `Z01_…`, `ZA0` → `ZA0_…`.
  - Customer field on a TOTVS table: same prefix; the differentiator is `X3_PROPRI = 'U'`, not the name.
- **Parameters** (`X6_VAR`):
  - Format: `MV_<YY><Name>` — `YY` = module (e.g. `ES` for cliente, `FS` for fábrica, `XX` for cross-module).
  - 10 chars max (X6_VAR is `Char(10)`).
  - Customer parameters: `MV_ES<Name>`. Fábrica de Software: `MV_FS<Name>`.
- **Indexes**:
  - `ORDEM` is a sequential char — `1`–`9`, then `A`–`Z`. Customer indexes typically start after TOTVS's last index for that table.
  - `NICKNAME` is a free 10-char tag. **Always set it** on custom indexes; you reference indexes via `DBOrderNickName(cNickName)` instead of `DBSetOrder(n)`, which protects you when TOTVS adds a new standard index in the next release and renumbers yours.
- **Field groups (SXG)**:
  - Groups identify a *concept* (product code, customer code) that recurs across tables. Adding `B1_COD` and `D1_COD` to the same SXG ensures resizing one updates the other.

## Source of truth and verification

Use the `advpl-tlpp-mcp-docs` MCP to inspect the **standard TOTVS dictionary**:

- `language-system-docs-search` for the official TDN page of any SX_ table.
- `execute-sql` against `SX2T10`, `SX3T10`, `SX6T10`, `SIXT10`, `SXGT10` to see the standard rows.
- `code-search` to find how TOTVS sources consume a particular field (e.g. `B1_DESC` references) before extending it.

This MCP reflects the reference TOTVS base, not the customer environment. For customer-side state (what the customer actually has), use ClaudeSQL or ask the user. Never assume.

## Detailed references

- **[tables.md](tables.md)** — SX2 attribute by attribute, modes, key, custom-table creation flow.
- **[fields.md](fields.md)** — SX3 attributes, virtual vs real, validators, picture, when, F3, triggers, X3_USADO binary handling, SXG groups.
- **[indexes.md](indexes.md)** — SIX structure, ORDEM vs NICKNAME, SHOWPESQ, custom-index lifecycle.
- **[parameters.md](parameters.md)** — SX6 attributes, MV_ naming, GetMV/SuperGetMV, branch scoping, language fallback.
- **[upddistr-rules.md](upddistr-rules.md)** — what UPDDISTR / migrador overwrite per dictionary; which customer changes survive an upgrade.
- **[examples.md](examples.md)** — concrete walk-throughs: create custom table, add field to SA1, create parameter, define filter index with nickname.
- **[anti-patterns.md](anti-patterns.md)** — pitfalls collected from TDN release notes and field experience.
