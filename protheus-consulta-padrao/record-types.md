# SXB Record Types

## Contents

- Common fields
- Category: Padrão (DB)
  - Type 1 — Tabela da consulta
  - Type 2 — Índices
  - Type 3 — Permissão de incluir
  - Type 4 — Campos exibidos por índice
  - Type 5 — Retornos
  - Type 6 — Filtro
  - Type 7 — Limite superior e inferior
  - Type 8 — Botão de consulta analítica
  - Type 9 — Fonte de manutenção da tabela
- Category: Específica (RE)
- Category: Usuário (US) e Grupo (GR)

## Common fields

Every SXB row has the same physical layout. The meaning of `XB_COLUNA`, `XB_SEQ`, `XB_DESCRI`, `XB_CONTEM` changes per `XB_TIPO`.

| Field | Type | Description |
| --- | --- | --- |
| `XB_ALIAS` | Char(6) | Consulta code. Same value across every row of the same consulta. **Not** the table alias (though it often matches). |
| `XB_TIPO` | Char(1) | Role of this row inside the consulta. Numeric 1–9. |
| `XB_SEQ` | Char(2) | Order/grouping inside the consulta + tipo. |
| `XB_COLUNA` | Char(2) | Role-dependent: query-type marker (type 1), index code (type 2), column ordering (type 4), unused on others. |
| `XB_DESCRI` | Char(20) | Label in Portuguese. |
| `XB_DESCSPA` | Char(20) | Label in Spanish. |
| `XB_DESCENG` | Char(20) | Label in English. |
| `XB_CONTEM` | Char(250) | Payload — table alias, field, expression, function call. Used in tipo 1, 4, 5, 6, 7, 8, 9. |

## Category: Padrão (DB)

The first row's `XB_COLUNA` is `DB`. This is the lookup over a regular Protheus table.

### Type 1 — Tabela da consulta

Mandatory. Exactly one row. Declares the table the consulta queries.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `1` | `01` | `DB` | `Cliente` | `SA1` |

- `XB_CONTEM` must be a table alias registered in SX2.
- Optional modifiers after the alias:
  - `A` (e.g. `N19A`) — enables the change button in the lookup modal.
  - `F<func>;<button label>;<return override>` — adds a button. Example: `SB1FA093SB1();Config;SBP->BP_BASE` adds a "Config" button that calls `A093SB1()`. The return override (last segment) replaces the type-5 return when the button is used.

### Type 2 — Índices

Mandatory. At least one row. Declares the search index(es) the user can pick from.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `2` | `01` | `01` | `Codigo` | `` |
| `SA1` | `2` | `02` | `05` | `N Fantasia` | `` |

- `XB_COLUNA` is the **index code** (the `Indice` in SIX). Must exist on the target table.
- `XB_DESCRI` labels the index in the "Pesquisa Por" dropdown.
- `XB_CONTEM` is empty for type 2.
- Each type-2 row must have a matching set of type-4 rows.

### Type 3 — Permissão de incluir

Optional. If present, the "Cadastra Novo" button is enabled.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `3` | `01` | `01` | `Cadastra Novo` | `01#A030INCLUI#A030VISUAL` |

- Default `XB_CONTEM` is `01` — invokes the routine declared in `SX2.X2_SYSOBJ` / `X2_USROBJ`, or `AxInclui()` as a fallback.
- Legacy `#` overrides:
  - `01#MyFunc()` — replaces only the insert routine with `MyFunc()`.
  - `01#MyInc()#MyView()` — replaces both insert and view routines.
  - `01#NO#MyView()` — disables insert, only allows view.
- **Modern alternative**: use type 9 instead. It is the supported path going forward.

### Type 4 — Campos exibidos por índice

Mandatory whenever type 2 exists. One row per displayed column per index.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `4` | `01` | `01` | `Codigo` | `A1_COD` |
| `SA1` | `4` | `01` | `02` | `Loja` | `A1_LOJA` |
| `SA1` | `4` | `01` | `03` | `Nome` | `A1_NOME` |
| `SA1` | `4` | `02` | `04` | `Codigo` | `A1_COD` |
| `SA1` | `4` | `02` | `05` | `Loja` | `A1_LOJA` |
| `SA1` | `4` | `02` | `06` | `Nome` | `A1_NOME` |

- `XB_SEQ` ties this row to the matching type-2 row's `XB_SEQ`.
- `XB_COLUNA` orders the columns on screen (across all type-4 rows, globally unique).
- `XB_CONTEM` is an SX3 field code from the table declared in type 1.
- The first column should be (or contain) the index leading field so navigation by typing works.

### Type 5 — Retornos

Mandatory. At least one row. Defines what gets written back to the calling field(s) on selection.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `5` | `01` |  |  | `SA1->A1_COD` |
| `SA1` | `5` | `02` |  |  | `SA1->A1_LOJA` |

- `XB_SEQ` orders returns. Sequential numbering, starting at `01`.
- `XB_CONTEM` is normally a physical field reference (`ALIAS->FIELD`). Any valid AdvPL expression works (e.g. `Posicione("SB1", 1, xFilial("SB1")+SA1->A1_PADRAO, "B1_DESC")`).
- The selected record is positioned before each expression is evaluated.
- Each return fills the calling field then the next field on the form (in the form's tab order). A consulta returning two values overwrites the focused field plus the next one.
- **The returned fields must be present in the chosen type-2 index** — otherwise positioning fails.

### Type 6 — Filtro

Optional. At most one row. Filters the displayed dataset.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `6` | `01` |  |  | `If(cGrupoCli=='',.T.,SA1->A1_GRPVEN==cGrupoCli)` |

- `XB_CONTEM` must be a valid AdvPL expression that returns a logical.
- Wildcards in `XB_CONTEM`:
  - `#expr` — `expr` is macro-executed every row. Use when the filter needs to vary at runtime (e.g. read a global variable).
  - `@#func()` — `func()` is evaluated **only once** before iteration. Cheap version of `#`; useful when the filter depends on a value that does not change during the consulta.
  - `@expr` — (v12+) `expr` is treated as SQL ANSI, pushed down to the database. Far faster than AdvPL row-by-row evaluation. Example: `@A1_COD IN ('000001','000002')`.
- For SQL filters that exceed 250 chars, combine `#` and `@` by calling a user function that returns the SQL string: `XB_CONTEM = "#U_FiltraSA1()"` and the function returns the `@A1_COD IN (...)` literal.

### Type 7 — Limite superior e inferior

Optional. Two rows: `XB_SEQ=01` upper bound, `XB_SEQ=02` lower bound. Used to restrict the consulta to a range of keys (typically by branch).

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `7` | `01` |  |  | `xFilial("SA1") + "ZZZZZZZZ"` |
| `SA1` | `7` | `02` |  |  | `xFilial("SA1")` |

- `XB_CONTEM` is an AdvPL expression that returns the limit value.
- Normally used for multi-branch consultas that should display only records of the current branch.

### Type 8 — Botão de consulta analítica

Optional. Adds an "Analítica" button that calls a custom analysis function.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `8` | `01` |  |  | `ACA240SXB()` |

- `XB_CONTEM` is the function called when the button is pressed.

### Type 9 — Fonte de manutenção da tabela

Optional. Replaces the source that owns insert/view operations for this consulta.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `9` | `AC` |  |  | `MATA122` |

- `XB_SEQ` must be `AC`.
- `XB_CONTEM` is the source name. Overrides `SX2.X2_SYSOBJ` and `X2_USROBJ`.
- Use this instead of the legacy `#` markers in type 3 when redirecting insert/view to a custom routine.

## Category: Específica (RE)

The query is implemented entirely by an AdvPL function. The SXB rows are scaffolding for the engine to find and execute that function.

### Type 1 — Cabeçalho

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `JURSX3` | `1` | `01` | `RE` | `Campos do Sistema` | `SA1` |

- `XB_COLUNA` is always `RE` for Específica.
- `XB_CONTEM` is optional — may carry a reference table alias but the function decides what to actually show.

### Type 2 — Function name

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `JURSX3` | `2` | `01` | `01` |  | `JURF3SX3()` |

- `XB_CONTEM` is the function called when the user presses F3.
- The function must populate the **public variable `VAR_IXB`** with the value(s) to return, then return `.T.` for confirm, `.F.` for cancel.

### Type 5 — Retorno

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `JURSX3` | `5` | `01` | `01` |  | `JURSX3->X3_CAMPO` |

- Evaluated after the function returns, with `VAR_IXB` already set.
- Use it to project the picked value into the destination field. Any valid AdvPL expression works.

## Category: Usuário (US) e Grupo (GR)

### Type 1 — Cabeçalho

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `USR` | `1` | `01` | `US` | `Usuários` |  |
| `GRP` | `1` | `01` | `GR` | `Grupos` |  |

- `XB_COLUNA` = `US` for user picker, `GR` for group picker.
- `XB_CONTEM` is empty.

### Type 5 — Retorno

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `USR` | `2` | `01` | `01` |  | `NAME` |

- Allowed return values: **`ID`** (user/group internal id) or **`NAME`** (display name). Nothing else.
