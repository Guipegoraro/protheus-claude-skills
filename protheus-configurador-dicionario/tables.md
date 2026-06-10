# SX2 — Tables

The SX2 registers every table the system knows about. Without an SX2 entry, a table cannot be opened with `DbSelectArea`, won't appear in any browse, and won't be backed by the RDD.

## SX2 attributes

| Field | Type | Purpose | Customer-editable |
| --- | --- | --- | --- |
| `X2_CHAVE` | Char(6) | The alias used in source code (`DbSelectArea("SA1")`). Must be unique. | No (key) |
| `X2_ARQUIVO` | Char(8) | Physical table name. TOTVS convention: `<X2_CHAVE> + <unit-of-business code> + "0"`. E.g., `SA1010` for SA1 in unit 01. With relational backends, this becomes the literal DB table name. | No |
| `X2_PATH` | Char | Filesystem path (relative to rootpath). Used only with ISAM (CodeBase/CTREE). Empty for relational. | Sometimes |
| `X2_NOME`, `X2_NOMESPA`, `X2_NOMEENG` | Char(40) | Display name in PT, ES, EN. | Yes |
| `X2_ROTINA` | Char | Routine called when the table is opened (rarely used). | Yes |
| `X2_MODO` | Char(1) | Branch share mode. `C` = compartilhada (one set of records across branches), `E` = exclusiva (records segmented by `X1_FILIAL`). | No (only via the dictionary upgrade dialog) |
| `X2_MODOUN` | Char(1) | Same idea, scoped to unit-of-business. | No |
| `X2_MODOEMP` | Char(1) | Same idea, scoped to company. | No |
| `X2_UNICO` | Char | Primary-key expression (e.g. `A1_FILIAL+A1_COD+A1_LOJA`). The engine uses this for `ExistChav` and similar. | Conditional |
| `X2_DISPLAY` | Char | Fields concatenated with `+` shown in the browse detail pane. | Yes |
| `X2_PYME` | Char(1) | Whether the table is used by Protheus Série 3 (PYME). | No |
| `X2_MODULO` | Num | Module code that owns the table. | No |
| `X2_SYSOBJ` | Char | Source file responsible for the maintenance routine (TOTVS). | No |
| `X2_USROBJ` | Char | Source file responsible if the customer overrode the maintenance routine. | Yes |
| `X2_MEMTYPE` | Char(1) | Memo storage: blank or `1` = BLOB, `2` = CLOB. | Yes |
| `X2_AUTREC` | Char(1) | RECNO auto-increment toggle. **Only applies to custom tables** (alias starting with `SZ*`, `Z*`, `P*`). `1` = on, `2` = off. | Yes (custom tables) |
| `X2_STAMP` | Char(1) | Creates the `S_T_A_M_P_` timestamp column on the physical table. `1` = on, `2` = off. **Available from release 12.1.2310. Irreversible after creation** — switching back to `2` does not drop the column. | Yes |
| `X2_INSDT` | Char(1) | Creates the `I_N_S_D_T_` insert-timestamp column. `1` = on, `2` = off. **Available from release 12.1.2410. Irreversible after creation**. | Yes |
| `X2_DELET`, `X2_TTS` | — | Not used (legacy). | — |

The `S_T_A_M_P_` / `I_N_S_D_T_` columns require DBAccess's global option to be on. They are useful for audit, CDC, and incremental sync.

## X2_MODO — share mode mechanics

The mode applies to the **whole table** and dictates whether a record is shared across branches/units/companies.

| Mode | Meaning | Typical use |
| --- | --- | --- |
| `C` (compartilhada) | One physical row visible from every branch (`xFilial(alias)` returns `""`). | Master data: parameters, generic tables. |
| `E` (exclusiva) | Each branch sees its own slice (`xFilial(alias)` returns the branch code, becomes part of the key). | Transactional data: orders, invoices, stock. |

Three columns control this at three levels — branch (`X2_MODO`), unit (`X2_MODOUN`), company (`X2_MODOEMP`). Modern Protheus uses all three; older versions only used `X2_MODO`.

**Never change `X2_MODO` on a table that already has data.** The position of the filial token in the key changes, every existing key breaks, every index breaks, every cross-reference breaks. If you absolutely must, do it on an empty environment or write a full data-migration script.

## Custom-table creation flow

Walk-through for creating a new table `ZA0`:

1. Pick the alias. Customer namespace: `Z<L><N>` (here `ZA0`) or `SZ<N>` (here `SZ0`).
2. Decide the share mode (`C` or `E`) based on whether the data is per-branch.
3. List the fields the table needs (write them out before opening the Configurador — see [fields.md](fields.md)).
4. List the indexes — at minimum, primary key with `SHOWPESQ = S`.
5. In Configurador → Base de Dados → Dicionário → Bases de Dados:
   - Click **Incluir**.
   - Fill `X2_CHAVE` (`ZA0`), `X2_ARQUIVO` (`ZA0` + unit code; the Configurador derives this), `X2_NOME` (description in PT, also fill ES and EN), `X2_MODO`, optionally `X2_DISPLAY`, `X2_USROBJ` if a custom maintenance routine.
   - Set `X2_AUTREC = 1` if you want RECNO auto-increment (recommended for custom tables).
   - Set `X2_STAMP = 1` and `X2_INSDT = 1` if you want audit columns (irreversible).
6. Save.
7. Add fields — see [fields.md](fields.md). The first field must always be `<prefix>_FILIAL` (Char, X3_USADO chave).
8. Add at least one index in SIX — see [indexes.md](indexes.md).
9. **Atualizar base de dados** to create the physical table.

## Extending TOTVS tables (vs creating a new one)

When the customer needs to attach data to an existing entity (customer, product, order):

- **First option**: add a custom field to the existing table (`A1_<NAME>` on SA1). One row per existing row, zero JOIN, zero new index. Use this when the relationship is 1-to-1.
- **Second option**: create a satellite table (`ZA0`) keyed by the parent's primary key (`ZA0_CLIENT + ZA0_LOJA`). Use this when you need 1-to-N data or when the extra columns would bloat the parent.

Adding a column to a 20-million-row SA1 is cheap on PostgreSQL/SQL Server. Creating a satellite table when you only ever need a single boolean is over-engineering.

## What survives a TOTVS upgrade (UPDDISTR)

UPDDISTR rules for SX2 (see [upddistr-rules.md](upddistr-rules.md) for the full matrix):

- `X2_CHAVE`, `X2_ARQUIVO`, `X2_PATH` — **never overwritten**. Your custom tables persist.
- `X2_MODO`, `X2_MODOUN`, `X2_MODOEMP` — **never overwritten** (customer-controlled).
- `X2_USROBJ` — **never overwritten**.
- `X2_ROTINA` — overwritten only if currently empty.
- `X2_UNICO` — overwritten only if the new key is *not contained* in the current key. Adding columns to the customer key is safe.
- Other columns (descriptions, display, module, …) — always overwritten by TOTVS values.

Implication: custom columns added to a TOTVS table survive, but if you renamed `A1_NOME`'s description or display, that change will be reverted on the next UPDDISTR.

## Useful functions

- `X2Nome()` — returns the current alias's description in the current language.
- `CHKFILE(alias)` — returns `.T.` if the table exists and can be opened. Use before `DbSelectArea` in optional features.
- `FWSX2Util` (newer versions) — programmatic access to SX2 metadata.
