# SIX — Indexes

The SIX defines every index for every table. Indexes drive the seek behaviour in `DbSetOrder` / `DBOrderNickName`, the consulta padrão search, the browse search-by, and the underlying database B-tree.

## SIX attributes

| Field | Type | Purpose |
| --- | --- | --- |
| `INDICE` | Char(6) | Table alias the index belongs to. |
| `ORDEM` | Char(2) | Sequential order — `1`–`9`, then `A`–`Z`. Used by `DbSetOrder(n)` after a numeric conversion. |
| `CHAVE` | Char | Key expression. Plus-concatenated SX3 field names. Must reference **real** fields only (`X3_CONTEXT = 'R'` or blank). |
| `DESCRICAO`, `DESCSPA`, `DESCENG` | Char | Index label in PT, ES, EN. Shown in browse "Pesquisar por" and in consulta padrão type-2 description. |
| `PROPRI` | Char(1) | `S` = system (TOTVS), `U` = user (customer). Configurador sets `U` automatically for customer-created indexes. |
| `F3` | Char | Lookup alias used by `AxPesqu` to build F3 modals. Rarely set on standard indexes. |
| `NICKNAME` | Char(10) | Stable alias for the index. **Always set it** on customer indexes. |
| `SHOWPESQ` | Char(1) | `S` to expose the index in browse "Pesquisar por", blank otherwise. |

The physical name of the index in the database is derived: `<X2_ARQUIVO><ORDEM>` (e.g. `SA1010A` for SA1, index ordem `A`).

## ORDEM — why nicknames matter

`ORDEM` is a sequential char. When TOTVS releases a new standard index for SA1 — say, index `A` for a new search-by — every customer index after the insertion point shifts. If you wrote `DbSetOrder(11)` against a custom index, it now seeks against the new TOTVS one, with predictable disasters.

The fix is **NICKNAME**:

```advpl
// Wrong — fragile across upgrades
DbSetOrder(11)

// Right — nickname is stable; the engine resolves ORDEM at runtime
DBOrderNickName("ZA0CLI")
```

Conventions for nicknames:

- 2–10 chars, uppercase, mnemonic (`SA1CLI`, `ZA0DTLI`).
- Nicknames are globally unique across all tables in newer LIBs (DFRM4-12096), so prefix them with the table alias when there's any ambiguity.
- TOTVS standard indexes generally **don't** have nicknames; you should not add one to them either.

## SHOWPESQ — the browse-visible index

`SHOWPESQ = 'S'` makes the index appear in the browse's "Pesquisar por" dropdown. Every table must have **at least one** index with `SHOWPESQ = 'S'` to be visible in browses at all.

Customer indexes are often non-visible: they exist purely to support an SQL filter or a SetFilter clause. Leave `SHOWPESQ` blank for those.

## Index lifecycle

For a new custom index `ZA0DTLI` on table ZA0 over field `ZA0_DTLIMITE`:

1. Confirm `ZA0_DTLIMITE` is real (`X3_CONTEXT = 'R'`) and exists in SX3.
2. In Configurador → Base de Dados → Dicionário → Bases de Dados → ZA0 → Editar.
3. Expand ZA0, click **Índices**, click **Incluir**.
4. Fill:
   - Ordem: the next free position (or any free letter A–Z).
   - Chave: `ZA0_FILIAL+ZA0_DTLIMITE+ZA0_COD`.
   - Descrição: `Data limite`.
   - Propriedade: usuário (auto).
   - Nickname: `ZA0DTLI`.
   - ShowPesq: `S` or blank depending on whether you want it in the browse.
5. Confirm.
6. Back on the table list, **Atualizar base de dados** (creates the physical index in modo exclusivo).

## Composite keys and filial prefix

The first segment of the key on any non-shared table (`X2_MODO = 'E'`) must be the filial field (`X1_FILIAL`-equivalent: `A1_FILIAL`, `D1_FILIAL`, `ZA0_FILIAL`). This is what enables branch isolation. Forgetting it makes the index leak rows across branches.

For shared tables (`X2_MODO = 'C'`), the filial segment is empty at runtime (`xFilial(alias) == ""`), so prefixing the key with the filial field is still correct — the prefix collapses to zero bytes.

## Index keys can include expressions

The key isn't limited to bare field names. Expressions and casts are valid:

```
A1_FILIAL + STR(A1_COD,6) + A1_LOJA
A1_FILIAL + DTOS(A1_DTCAD)
A1_FILIAL + Upper(A1_NOME)
```

Use cautiously — expression indexes are not portable across all backends (PostgreSQL supports them, SQL Server's restriction set is narrower). When in doubt, keep the key plain.

## When NOT to add an index

- The query already runs in milliseconds. An index is overhead on every insert/update.
- The filtered selectivity is poor (low cardinality column like a `S/N` flag).
- The table is high-write, low-read.

Use the `query-builder` skill to pick an existing SIX index before creating a new one.

## UPDDISTR behaviour

For SIX, UPDDISTR generally inserts new TOTVS-shipped indexes and leaves customer indexes (`PROPRI = 'U'`) alone — see [upddistr-rules.md](upddistr-rules.md). The risk is that your customer index `ORDEM = 'B'` gets re-numbered when TOTVS ships a new standard `ORDEM = 'B'`. **Nicknames make this risk invisible**: even if ORDEM moves, your code keeps working.

## Functions

| Function | Purpose |
| --- | --- |
| `DbSetOrder(n)` | Seeks against ORDEM `n`. Fragile across upgrades — avoid for customer indexes. |
| `DBOrderNickName(cNick)` | Seeks against the nicknamed index. Preferred. |
| `IndexKey(n)` | Returns the key expression of order `n`. |
| `IndexCount()` | Number of indexes on the current alias. |
| `DbSeek(cKey, lSoft)` | Seek for a key in the current order. `lSoft = .T.` does a partial match. |
| `DbSetIndex` / `RetIndex` | Legacy / programmatic index attach. Rarely needed in modern code. |
