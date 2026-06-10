# SX3 — Fields (and SXG groups)

The SX3 carries every column-level attribute for every table the system knows about. The set of attributes is large but most have stable defaults; only a handful are routinely set by hand.

## Contents

- SX3 attribute reference (every X3_*)
- Field types
- Real vs virtual fields (`X3_CONTEXT`)
- Use, key, alterable, mandatory — the binary fields
- Triggers (SX7)
- SXG — Field Groups
- Field-creation workflow

## SX3 attribute reference

The columns the customer routinely fills in are highlighted.

| Field | Type | Purpose |
| --- | --- | --- |
| `X3_ARQUIVO` | Char(6) | Table alias the field belongs to. Must match an SX2 key. |
| `X3_ORDEM` | Char(2) | Order of presentation on screen. Lookups returning multiple values rely on this order — see [protheus-consulta-padrao](../protheus-consulta-padrao/SKILL.md). |
| `X3_CAMPO` | Char(10) | Field name. Must be unique inside the table. For `S*` tables, drop the `S` (`SA1` → `A1_…`, max 7 chars after the underscore). For non-`S*` tables, keep the full prefix (`Z01_…`, max 6 chars after). |
| `X3_TIPO` | Char(1) | `C` Character, `N` Numeric, `D` Date, `M` Memo, `L` Logical. |
| `X3_TAMANHO` | Int | Size in characters / digits. Max 254 chars. **If `X3_GRPSXG` is set, size is overridden by the SXG group**. |
| `X3_DECIMAL` | Int | Decimal places. Only meaningful for `X3_TIPO = 'N'`. |
| `X3_TITULO`, `X3_TITSPA`, `X3_TITENG` | Char | Short label shown on screen (PT/ES/EN). |
| `X3_DESCRIC`, `X3_DESCSPA`, `X3_DESCENG` | Char | Long description (PT/ES/EN). |
| `X3_PICTURE` | Char | Display mask. E.g. `@!` upper case, `@E 999.99` numeric formatting, `@R 99.999.999/9999-99` for CNPJ. |
| `X3_VALID` | Char | System-side validation expression. Evaluated after the user types. `User Function`/`Function` only — `Static Function` does not work here. Example: `ExistCpo("SX5","12"+M->A1_EST)`. |
| `X3_VLDUSER` | Char | Customer-side validation expression. Pre-filled by TOTVS in some cases, but the customer is expected to override. |
| `X3_USADO` | Char (binary-ish) | Module-use bitmap. **Read with `X3Uso()` or `X3Chave()` / `X3Alteravel()`. Never via `Bin2Str`/`SubStr` directly.** |
| `X3_RELACAO` | Char | Default initialiser expression evaluated on insert (and sometimes for virtual fields on every read). Example: `dDataBase`. |
| `X3_F3` | Char(6) | `XB_ALIAS` of the lookup (consulta padrão). See the `protheus-consulta-padrao` skill. |
| `X3_NIVEL` | Char(1) | Access level. `0`–`9`. Compared with the user's level on screen rendering. |
| `X3_RESERV` | Char (binary-ish) | Field-attribute reservation flags. Read with `X3Reserv()`. |
| `X3_TRIGGER` | Char(1) | `S` if there are SX7 gatilhos linked to this field, blank otherwise. |
| `X3_PROPRI` | Char(1) | `U` for customer-created, blank/`S` for TOTVS. Set automatically when the field is created by a logged-in customer user. |
| `X3_BROWSE` | Char(1) | `S` to show the field in browse listings, `N` otherwise. |
| `X3_VISUAL` | Char(1) | Blank or `A` editable, `V` visualisation only. |
| `X3_CONTEXT` | Char(1) | Blank or `R` real (stored physically), `V` virtual (computed at runtime, not stored). |
| `X3_OBRIGAT` | Char (binary-ish) | Whether the field is mandatory at the application level. Read with `X3Obrigat(cField)`. |
| `X3_CBOX`, `X3_CBOXSPA`, `X3_CBOXENG` | Char | Combo options. Format: `Letter=Label;Letter=Label;...` (e.g. `F=Cons.Final;L=Produtor Rural;R=Revendedor`). |
| `X3_PICTVAR` | Char | Runtime expression that returns the picture (e.g. switch between CPF/CNPJ mask based on `A1_PESSOA`). |
| `X3_WHEN` | Char | Expression evaluated on every focus change. Returns logical: `.T.` field is editable, `.F.` field is disabled. Keep it cheap — runs on every keystroke focus change. |
| `X3_INIBRW` | Char | Function called when a browse opens. Mandatory for virtual fields in browses. |
| `X3_GRPSXG` | Char(3) | SXG group code. Linking groups consistent-sized fields together. |
| `X3_FOLDER` | Char | Folder/tab number the field appears on. SXA folder definition. |
| `X3_PYME` | Char(1) | Used by Série 3. |
| `X3_AGRUP` | Char(2) | SXA agrupador code — used by MVC views to group fields inside a folder. |
| `X3_IDXSRV`, `X3_IDXFLD` | Char | Protheus Search (Lucene/OpenSearch) indexing flags. |
| `X3_ORTOGRA` | Char(1) | Spell-checker on/off. |
| `X3_TELA` | Char | Bitmap controlling screen visibility per context. Use perfis de usuário in MVC instead. |
| `X3_POSLGT` | Char | Flag for TOTVS PDV export. |
| `X3_MODAL` | Char | Used in modal windows. |
| `X3_CHECK`, `X3_CONDSQL`, `X3_CHKSQL` | — | Not used. |

## Field types

| `X3_TIPO` | Storage | Notes |
| --- | --- | --- |
| `C` | Character | Default for codes, names, descriptions. Max 254. |
| `N` | Numeric | Use `X3_DECIMAL` for fractional. Picture controls display. |
| `D` | Date | 8-char internal storage (`YYYYMMDD`). |
| `M` | Memo | Variable-length text. Stored as BLOB or CLOB depending on `X2_MEMTYPE`. |
| `L` | Logical | `.T.` / `.F.`. Always 1 byte. |

There is **no boolean-as-char convention**. Custom code that uses `C(1)` with `'S'`/`'N'` is technically a string field and won't render as a checkbox; it will display as a text input.

## Real vs virtual fields (`X3_CONTEXT`)

| Context | Stored? | Use case |
| --- | --- | --- |
| `R` or blank — **real** | Yes, persisted to the DB | Default. Use unless you have a reason not to. |
| `V` — **virtual** | No, computed on the fly | Display-only derivations (`A1_NREDUZ` showing first 20 chars of `A1_NOME`, lookups via `Posicione`). Set `X3_RELACAO` to the computing expression. Set `X3_INIBRW` to the browse initialiser. |

**Mind the trade-offs of virtual fields**:

- Pro: no extra column on the physical table; no risk of stale data.
- Con: the value is recomputed on every read; complex `X3_RELACAO` expressions on large browses are slow.
- Con: cannot be indexed; you can't search by a virtual field in a consulta padrão.

For lookups that need joins, prefer a `Posicione`-based virtual field for the display column and a real foreign-key column for the actual storage.

## Use, key, alterable, mandatory

These four flags ride inside a small set of attributes that look like strings but are bit-packed.

| Concept | Backing field | Read with | Write with |
| --- | --- | --- | --- |
| In use in module N | `X3_USADO` | `X3Uso(cUsado, nModulo)` | Configurador checkboxes |
| Key field | `X3_USADO` | `X3Chave(cUsado)` | Configurador "Chave" checkbox |
| Alterable | `X3_USADO` | `X3Alteravel(cUsado)` | Configurador "Não alterável" checkbox |
| Reserved | `X3_RESERV` | `X3Reserv(cReserv)` | Configurador "Reservado" checkbox |
| Mandatory at app level | `X3_OBRIGAT` | `X3Obrigat(cField)` | Configurador "Obrigatório" checkbox |

**Critical**: in older versions these fields were binary; from 12.1.7 they became character but with opaque encoding. Direct manipulation (`Bin2Str`, `SubStr`, `Alltrim`) breaks across versions. **Always use the helper functions**.

## Triggers (SX7)

A field can fire an SX7 gatilho when it changes value. The link is `X3_TRIGGER = 'S'` plus one or more SX7 rows keyed by `X7_CAMPO`. See the `entry-point-designer` skill for hooks and the SX7 reference below.

Trigger types:

| `X7_TIPO` | Name | Behaviour |
| --- | --- | --- |
| `P` | Primário | After the source field validates, the rule (`X7_REGRA`) is macro-executed and the result is written to `X7_CDOMIN`. |
| `E` | Estrangeiro | Same idea but the target field lives on a different table; the write happens at form-confirm time. |
| `X` | Posicionamento | Positions a table (`X7_ALIAS`) by key (`X7_CHAVE`) so subsequent expressions can read its fields. |

Use case: `A1_EST` fires a gatilho that fills `A1_INSCR` with the right state-tax-id format. Replaces ad-hoc `If/Else` in `X3_VALID`.

## SXG — Field Groups

A field group is a code (3 chars, `X3_GRPSXG`) that ties together every field representing the same concept across the ERP. The canonical example: the product code. Tables SB1, SD1, SD2, SD3, SC5, SC6 (and 50 others) all have a product-code column. If the customer needs to grow it from 15 chars to 30, **changing one field in SX3 is not enough** — every related field must grow, every index must rebuild, every screen must adjust.

SXG solves this. Linking a field to a group means:

- The size shown in the Configurador is the **group's size** (`XG_SIZE`), not `X3_TAMANHO`.
- Changing `XG_SIZE` propagates to every member field.
- `XG_SIZEMIN` and `XG_SIZEMAX` clamp how far the size can move.

| Field | Type | Purpose |
| --- | --- | --- |
| `XG_GRUPO` | Char(3) | Group code (e.g. `033` for the product-code group). |
| `XG_DESCRI`, `XG_DESSPA`, `XG_DESENG` | Char | Description. |
| `XG_SIZE` | Num | Current size — the effective size for every member field. |
| `XG_SIZEMAX` | Num | Hard upper bound. |
| `XG_SIZEMIN` | Num | Hard lower bound. |
| `XG_PICTURE` | Char | Common picture for all members. |

**Always link a custom field to an existing SXG group when one applies.** Adding `Z9_PRODUT` (a custom product reference) without `X3_GRPSXG = '033'` will diverge from the rest of the ERP the moment someone resizes the product code.

`FWSX3Util():GetAllGroupFields(cGroup)` returns every field in a group — useful when auditing.

## Field-creation workflow

For a custom field `A1_DTLIMITE` (date) on the standard SA1:

1. In Configurador → Base de Dados → Dicionário → Bases de Dados.
2. Find SA1 in the list, click **Editar**.
3. Expand the SA1 node, click **Campos**, click **Incluir**.
4. Fill the **Campo** tab:
   - Campo: `A1_DTLIMITE` (uses the table's prefix; max 7 chars after `A1_` for `S*` tables).
   - Tipo: `D`.
   - Tamanho: `8`.
   - Contexto: Real.
   - Propriedade: Usuário (set automatically when logged in as a customer user).
5. Fill the **Informações** tab:
   - Título: `Data Limite`.
   - Descrição: `Data limite para análise de crédito`.
   - Picture: `@!`.
   - Inicializador padrão: blank, or `dDataBase + 30` if you want a 30-day-from-today default.
6. Fill the **Uso** tab:
   - Usado: yes (which modules).
   - Browse: yes/no.
   - Obrigatório: no.
7. Click **Salvar**.
8. Back on the field list, click the **confirm** (checkmark) icon.
9. Back on the table list, click **Atualizar base de dados**.
10. Confirm in modo exclusivo. The Configurador creates the physical column.

**Document this in `.claude/plans/<slug>/pre-producao.md`** with every attribute, so the same steps are reproducible on production.

For a custom field on a custom table (`ZA0`), the only difference is step 2 — you create the table first ([tables.md](tables.md)), then loop adding fields.

For a virtual field:

- Tipo: `C`/`N`/`D`/`L` as needed.
- Contexto: `V`.
- `X3_RELACAO`: the expression producing the value (e.g. `Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")`).
- `X3_INIBRW`: the browse initialiser, same expression usually.
- The field will not be created physically — only in the dictionary.

## Useful functions

| Function | Purpose |
| --- | --- |
| `X3Titulo()`, `X3Descric()`, `X3Picture()` | Localised title/description/picture for the positioned SX3 row. |
| `X3Uso(cUsado, nModulo)` | Whether the field is in use in a module. |
| `X3Chave(cUsado)` | Whether the field is part of the primary key. |
| `X3Alteravel(cUsado)` | Whether the field is editable. |
| `X3Reserv(cReserv)` | Whether the field is reserved (system-locked). |
| `X3Obrigat(cField)` | Whether the field is mandatory. |
| `X3CBox()` | Combo option list. |
| `GetSx3Cache(cField, cAttr)` | Cached SX3 attribute reader. Use it instead of `DbSeek` loops. |
| `FWSX3Util():GetAllFields(cAlias)` | All fields of a table. |
| `FWSX3Util():GetAllGroupFields(cGroup)` | All fields in an SXG group. |
| `FWSX3Util():GetFieldStruct(cField)` | Struct `[name, type, size, dec, picture]` of a field. |

Standard validation helpers used in `X3_VALID`:

| Helper | Purpose |
| --- | --- |
| `ExistChav(alias, key)` | True if a record with this key already exists. Use on insert. |
| `ExistCpo(alias, value)` | True if `value` exists as a key on `alias`. Use on foreign-key fields. |
| `NaoVazio()` / `Vazio()` | Mandatory / forbid value. |
| `Pertence("ABC")` | Value must be one of the listed characters. |
| `CGC()` | CPF or CNPJ validator. |
| `DataValida()` | Calendar date validator. |
| `Positivo()` / `Negativo()` | Sign check. |
| `Entre(min, max)` | Range check. |
