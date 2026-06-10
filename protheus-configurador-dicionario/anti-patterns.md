# Anti-patterns

Pitfalls collected from TDN release notes, the standard Protheus codebase, and field experience. Flag any of these in code review.

## Dictionary mutation in source files

```advpl
// WRONG — production source rewriting the dictionary
DbSelectArea("SX3")
RecLock("SX3", .T.)
    X3_ARQUIVO := "SA1"
    X3_CAMPO   := "A1_MYFLD"
    X3_TIPO    := "C"
    X3_TAMANHO := 10
    X3_TITULO  := "My Field"
MsUnlock()
```

**Why it's wrong**:

- Inconsistent state if the script fails mid-way (one column committed, the rest not).
- The new field exists in SX3 but not in the physical table — every query against SA1 with the new column breaks.
- Cache: sessions already connected don't see the new field until reconnect; mixed-state errors abound.
- UPDDISTR / Configurador audit logs flag the manual write as a tamper.
- From recent LIBs, SX3 audit is non-disableable. The change is logged regardless.

**Right approach**: Configurador → Base de Dados → Dicionário → Bases de Dados → SA1 → Editar → Campos → Incluir. Document the row in `.claude/plans/<slug>/pre-producao.md`.

The same applies to `RecLock("SX2")`, `RecLock("SX6")` / `PutMV`, `RecLock("SIX")`. The only legitimate runtime dictionary write is in migrators owned by the dictionary upgrade flow.

## Custom table outside the customer namespace

```
X2_CHAVE = "ABC"   -- not in Z?? or SZ?
```

**Symptom**: works today. Tomorrow TOTVS releases module `ABC` and your data gets overwritten by the migrator. Or `UPDDISTR` flags the conflict and refuses to apply.

**Fix**: use `Z<L><N>` (`ZA0`, `ZB1`, …) or `SZ<N>` (`SZ0`, …, `SZ9`, `SZA`–`SZZ`). These are the only ranges Microsiga guarantees they will never use.

## Adding a field with a custom prefix to a TOTVS table

```
X3_ARQUIVO = "SA1"
X3_CAMPO   = "Z_LIMITE"   -- wrong prefix
```

**Symptom**: the Configurador may even accept it on older versions, but every framework function that derives prefix from table (`A1_*`-aware code) skips this column. Browses behave strangely.

**Fix**: use the table's prefix: `A1_LIMITE`. Customer ownership is indicated by `X3_PROPRI = 'U'`, set automatically when you create the field as a customer user.

## Direct read of `X3_USADO`, `X3_RESERV`, `X3_OBRIGAT`

```advpl
// WRONG — relies on binary encoding that changed in 12.1.7
If SubStr(Bin2Str(SX3->X3_USADO),101,1) == "x"
    // field is in use in module 101
EndIf

// WRONG — relies on string padding that the storage no longer guarantees
If Alltrim(Upper(SX3->X3_USADO)) <> Replicate(Chr(128), 14)
    // ...
EndIf
```

**Why**: from 12.1.7 the storage changed from binary to character with opaque packing. Direct introspection breaks silently — code returns wrong booleans, fields appear to be unused, validators skip rows they should hit.

**Fix**:

```advpl
If X3Uso(SX3->X3_USADO, nModulo)
    // ...
EndIf

If X3Chave(SX3->X3_USADO)
    // is a key field
EndIf

If X3Alteravel(SX3->X3_USADO)
    // editable
EndIf

If X3Obrigat("A1_NOME")
    // mandatory
EndIf

If X3Reserv(SX3->X3_RESERV)
    // reserved
EndIf
```

These helpers are version-aware. Use them everywhere.

## Resizing a field that belongs to an SXG group via SX3

```
SX3->A1_COD.X3_TAMANHO = 20   -- via Configurador, on a field with X3_GRPSXG set
```

**Symptom**: the resize doesn't happen, or only happens on this one field while every other member of the group keeps the old size. Joins and seeks between the table and its siblings fail.

**Fix**: resize the SXG group (`XG_SIZE`) instead. The group's size propagates to every member field atomically. If you really need to break out, remove the field from the group first (clear `X3_GRPSXG`) — but think hard before doing it; the conceptual coupling exists for a reason.

## Using `DbSetOrder(n)` against a custom index

```advpl
// WRONG — fragile
DBSelectArea("SA1")
DBSetOrder(11)   // assumes the customer index is at ORDEM 11
```

**Symptom**: TOTVS ships a new standard index in the next release; existing customer indexes shift to ORDEM 12+. `DBSetOrder(11)` now seeks against an unrelated TOTVS index. Behaviour silently changes.

**Fix**:

```advpl
DBSelectArea("SA1")
DBOrderNickName("SA1MYIDX")
```

The nickname is resolved to ORDEM at runtime. Stable across upgrades.

## Reading SX6 without a default

```advpl
// WRONG — crashes if the parameter doesn't exist
Local nLimit := SuperGetMV("MV_ESCRDLM")
```

**Symptom**: works in the dev environment (where you created the parameter). The fresh customer deploy doesn't have the parameter yet → `Type "U" found, expected "N"` at the first arithmetic op.

**Fix**:

```advpl
Local nLimit := SuperGetMV("MV_ESCRDLM", .F., 1000.00)
```

Always pass the third-arg default. The argument doubles as documentation of the expected fallback.

## Calling `PutMV` to "write back" a value at runtime

```advpl
PutMV("MV_ESCRDLM", 2000.00)   -- in production source
```

**Why it's wrong**: PutMV mutates the dictionary. Every connected session has cached the old value (SuperGetMV cache); some see the new value, some don't. UPDDISTR audit flags it. The customer's intentional configuration is silently overwritten by application logic.

**Fix**: if a value needs to change per branch, model it as a regular table. If a value is configuration, only the customer (via Configurador) changes it.

## Changing `X3_TIPO` or `X3_TAMANHO` on a TOTVS field

```
SX3->A1_COD.X3_TAMANHO = 10   -- TOTVS field, no SXG group
```

**Symptom**: UPDDISTR overwrites the new size with the TOTVS default on the next release. Worse, if you went from `C(6)` to `C(10)` and inserted data with the 10-char form, the migrator reverts the metadata and the existing data becomes inconsistent — values truncated, key seeks failing.

**Fix**: don't change the TOTVS field. If you need a wider field, add a new custom field (`A1_MYCOD`) or extend the SXG group (which TOTVS respects per the UPDDISTR rules).

## Creating fields by abandoning the prefix because "the prefix is full"

```
SX2->SA1 already has 200 fields, X3_CAMPO uses up A1_ABCDEFG ...
SX3->A1_MYFLD2   -- the customer ran out of A1_* combinations
```

**Symptom**: rare in practice, but when it happens, the temptation is to put data under a "Z_*" prefix on SA1 — which then doesn't render in standard browses.

**Fix**: create a satellite table (`ZA0` keyed by `A1_COD + A1_LOJA`) and store the extra columns there. The 1-to-1 cardinality matches what you want; the data is cleanly separated.

## Forgetting to update the physical table

In Configurador: created the field, saved, confirmed at the field list, **didn't** click "Atualizar base de dados".

**Symptom**: the field exists in SX3, but not on the physical table. `DbSelectArea(alias); aFields := alias->(FieldName())` returns it; `SELECT A1_MYFLD FROM SA1` returns "column does not exist". Confusing errors at the next page reload.

**Fix**: always finish with **Atualizar base de dados** in modo exclusivo.

## Updating base de dados while users are connected to the table

The dialog at "Atualizar base de dados" warns you, and most of the time it really does require exclusive access. If you click through:

**Symptom**: the update fails silently or partially. Some fields exist physically, others don't. Some indexes built, others didn't. The Configurador may report success while the DB is half-updated.

**Fix**: schedule the apply for after-hours. Use Configurador → Gestão de Ambientes → Apply Project to bundle a set of changes that get applied transactionally.

## Treating a custom parameter as TOTVS-owned

```
X6_VAR    = "MV_FATPREC"   -- looks like a TOTVS naming
X6_PROPRI = "S"            -- forced to system
```

**Symptom**: at the next UPDDISTR, the parameter is treated as TOTVS. If the new TOTVS pacote has a parameter with this name, your value is preserved by the SX6 rule, but every other column (descrição, valid) gets overwritten.

**Fix**: use `MV_ES*` or `MV_FS*` for new customer parameters. Leave `X6_PROPRI = 'U'`.

## Designing a per-row toggle as a parameter

Customer asks: "I want to enable feature X for orders over $1000". You add `MV_ESFEATX = 1000.00`.

**Symptom**: a year later they want feature X only for premium customers. SX6 has no per-customer dimension. The "fix" is to start parsing the parameter as a complex string.

**Fix**: model the toggle as a field. Add `A1_FEATX` (Logical), `A1_LIMITE` (Numeric), let `X3_VALID` enforce the rule per row. The dictionary cost is one-time; the flexibility lasts.

## Mutating audit columns (`S_T_A_M_P_`, `I_N_S_D_T_`) manually

```advpl
RecLock("SA1", .F.)
    SA1->S_T_A_M_P_ := ...
MsUnlock()
```

**Why it's wrong**: those columns are managed by DBAccess. The framework writes them on every insert/update via the database driver. Direct writes corrupt the timestamp semantics and may be reverted on the next save.

**Fix**: read only. If the audit value is wrong, that's a DBAccess configuration issue, not an application issue. Don't paper over it from AdvPL.

## Disabling `X2_STAMP = 2` to "revert" the audit column

`X2_STAMP = 1` creates `S_T_A_M_P_` on the physical table. Setting `X2_STAMP = 2` afterwards does **not** drop the column — the SX2 flag and the physical schema have diverged.

**Symptom**: the column still exists on the DB; queries that select `*` still return it; some routines stop populating it; partial data.

**Fix**: if the audit column is genuinely unwanted, drop it manually at the DB level (after backup) and set `X2_STAMP = 2`. Or, more commonly, just leave it on — the overhead is negligible.

## Multi-language parameter content split across `X6_CONTEUD` and `X6_CONTSPA`

`X6_CONTEUD = "FATURADO"`, `X6_CONTSPA = "FACTURADO"`, `X6_CONTENG = "BILLED"`.

This is correct **for descriptions**. It is wrong **for parameters whose value is consumed by code**:

```advpl
If cStatus == GetMV("MV_ESSTATUS")   // returns "FATURADO" in PT, "FACTURADO" in ES
    // breaks when the session language is ES
EndIf
```

**Fix**: for code-consumed parameters, use a stable token (e.g. `BILLED`) regardless of language. Translate it on the UI side. Reserve multilingual `X6_CONTEUD` for parameters whose value is displayed verbatim to users.
