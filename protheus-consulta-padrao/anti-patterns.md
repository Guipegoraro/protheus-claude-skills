# Anti-patterns

Mistakes encountered in real Protheus customisations. Flag any of these in code review.

## Dictionary mutation in source files

```advpl
// WRONG — never do this in production source
DbSelectArea("SXB")
RecLock("SXB", .T.)
    XB_ALIAS  := "ZCONS1"
    XB_TIPO   := "1"
    XB_COLUNA := "DB"
    XB_CONTEM := "SA1"
MsUnlock()
```

**Why it's wrong:**

- Dictionary mutations from runtime fontes leave the environment inconsistent if they fail mid-way (one record committed, the rest not).
- `UPDDISTR` and the migrator expect the **Configurador** to own SXB. Concurrent writes from source produce ghost entries that the next upgrade silently overwrites.
- Cache effects: clients connected at the moment of the write do not see the change until reconnect.

**Right approach:** use the **Configurador → Base de Dados → Dicionário → Consultas Padrão**. Document the rows in `.claude/plans/<slug>/pre-producao.md` so the deploy applies them.

The only legitimate runtime SXB write is in migrators that explicitly own the dictionary at upgrade time.

## `@` push-down with dynamic variable in type-6 filter

```
WRONG: @BE_LOCAL = '"+M->CP_ZARDEST+"'
```

**Why it's wrong:**

The `@` prefix tells Protheus to push the rest of the string as a literal SQL WHERE clause to the database. There is **no runtime variable expansion** inside the `@` block — the string `'"+M->CP_ZARDEST+"'` is sent verbatim as text to the database, producing `WHERE BE_LOCAL = '"+M->CP_ZARDEST+"'`, which matches zero rows. The filter silently returns an empty result — operator presses F3 and sees nothing, with no error message.

Verified against the real TOTVS SXB: every type-6 filter using `@` in the standard dictionary uses **constants** (`@G3B_TIPO = '1'`, `@ADK_CORP = 'T'`, `@A1_COD IN ('000001','000002')`) — never runtime variables.

**Right approach (two options):**

- **For simple dynamic filters by a memory variable**: use plain AdvPL expression, no `@`:
  ```
  SBE->BE_LOCAL == M->CP_ZARDEST
  ```
  Evaluated row by row but works with any memory variable.

- **For push-down speed with a dynamic value**: use the macro `#` form pointing to a User Function that builds the SQL string at runtime:
  ```
  Type 6 content: #U_FltSBEMIC()
  ```
  ```advpl
  User Function FltSBEMIC()
      Return "@BE_LOCAL = '" + AllTrim(M->CP_ZARDEST) + "'"
  Return
  ```
  The `#` triggers macro substitution **once**, runs the function, then the returned `@...` string is treated as static SQL and pushed down.

**⚠️ Important:** if the variable feeding the filter is a **grid field** (lives in `aCols`, not in the Enchoice), `M->FIELD` is unreliable inside the filter — see *Reading `M->FIELD` from a grid context* below. Replace `M->FIELD` with `GDFieldGet("FIELD")` in the User Function.

## Reading `M->FIELD` from a grid context

```advpl
// WRONG — when CAMPO is a grid field (aHeader/aCols)
User Function MyFilter()
    Local cFiltro := "@1=2"
    If Type("M->CAMPO") == "C"
        cFiltro := "@OTHER_FIELD = '" + AllTrim(M->CAMPO) + "'"
    EndIf
Return cFiltro
```

**Why it's wrong:**

`M->FIELD` is the memory-variable proxy that Protheus binds to **Enchoice fields** (form-level cabeçalho). For **grid fields** (rows in `oGetDados`, backed by `aHeader`/`aCols`), `M->FIELD` is created and populated only at very specific moments of the row-edit lifecycle — and it is **not reliable** during evaluation of:

- Type-6 SXB filters (pressing F3 on a grid field)
- `X3_VALID` of a grid field referencing **other** grid fields on the same row
- Triggers and CPO callbacks that read sibling grid fields

In many cases the variable doesn't even exist in scope (`Type("M->CAMPO") <> "C"`), so any defensive `If Type(...) == "C"` simply falls through and the function returns its empty/default branch — operator sees "filter matches everything" or "validation always accepts", with no error.

**Symptom recipe:** customisation works "by feel" if the operator tabs through fields in a specific order, fails otherwise. Or: filter returns all rows ignoring the dependency. Or: F3 modal is empty when it should be filtered. No exception, no log entry.

**Right approach — use the framework's grid accessors:**

```advpl
// CORRECT — reads the grid row's current value
cArmDest := AllTrim(GDFieldGet("CP_ZARDEST"))

// Optional fallback: M-> for the (rare) case the function is called
// from a non-grid context. Order is intentional: grid first, M-> second.
If Empty(cArmDest) .And. Type("M->CP_ZARDEST") == "C"
    cArmDest := AllTrim(M->CP_ZARDEST)
EndIf
```

Three TOTVS-blessed alternatives, in order of preference:

1. **`GDFieldGet("FIELD")`** — the generic helper. Reads the current row of the active getDados, no extra parameters. Used by TOTVS in `DEL` (`DEL->DEL_CODMOT == GDFieldGet('DUP_CODMOT',n)`), `JAR001`/`JAR002`, `CLN2`.

2. **`aCols[n][nPosX]`** — direct array access when you control the surrounding code. Used by TOTVS in `SB8` (`SB8->B8_PRODUTO == aCols[n,nPosCProd]`), `QEL`, `QPL`, `XP1`, `W13` (the last uses `aScan(aHeader, ...)` to resolve the index dynamically).

3. **`oGetDados:aCols[oGetDados:nAt][nPos]`** — when you have an explicit reference to the object. Used by TOTVS in `AA3_02` (`AA3->AA3_CODPRO == oGetDados:aCols[oGetDados:nAt,nPosiProd]`), `MHICHG`, `ST9FPA`.

**Quick test in the field:** if you wrote a type-6 filter that depends on a grid field and the F3 either returns nothing or returns everything regardless of what the operator typed, the first hypothesis is `M->FIELD` being read from a grid context. Replace with `GDFieldGet` and retry.

## Return field absent from the chosen index

Consulta returns `A1_CGC`, but the only index (type 2) is `01 = A1_FILIAL+A1_COD+A1_LOJA`.

**Symptom:** selecting a row returns a value, but the next time the user opens the form, the F3 modal cannot position by the saved value (CGC is not in the index path).

**Fix:** add an index that contains the returned field (e.g. `04 = A1_FILIAL+A1_CGC`) as a type-2 row, with matching type-4 columns. Or return the indexed key (`A1_COD+A1_LOJA`) instead and let the form's `Trigger`/`When` look up the CGC.

## Functions or `IF` in type-5 returns, when Smart View consumes the consulta

```
XB_TIPO=5, XB_CONTEM = If(A1_TIPO=='F', U_FormatPF(A1_CGC), U_FormatPJ(A1_CGC))
```

**Symptom:** the consulta works in the AdvPL UI but `GenericLookupService` returns blank values to Smart View / REST callers. The service quietly drops any return containing `IF`, `IIF`, `&`, `@`, `#`, or a function call (except `Posicione`).

**Fix:** keep type 5 to plain field references, concatenations of SX3 fields, or `Posicione`. Push formatting to the consumer (Smart View formatter, view callback, or REST projection).

## Type-3 `#` markers when tipo 9 is supported

Legacy:

```
XB_TIPO=3, XB_CONTEM = '01#MATA410(,,3)#MATA410(,,2)'
```

Modern:

```
XB_TIPO=9, XB_SEQ='AC', XB_CONTEM = 'MATA410'
```

**Why prefer tipo 9:** clearer intent, single source of truth, no parsing of magic `#`-separated tokens, supported going forward. The `#` form still works but is documented as legacy.

## Custom consulta cloning a TOTVS alias

```
XB_ALIAS = 'SA1'   -- same code as TOTVS standard
XB_CONTEM = 'SA1FA093SB1();...'   -- added a custom button
```

**Symptom:** the next LIB update or UPDDISTR run overwrites the entire `SA1` consulta. The customisation vanishes silently. `UPDDISTR` deletes all rows of the consulta and reinserts the standard ones — there is no partial merge.

**Fix:** create a new `XB_ALIAS` (`ZSA1`, `SA1FX`, etc.) and wire it via `SX3.X3_F3` on the affected fields. Customisations live under custom aliases, never under TOTVS standard ones.

## Type-6 filter doing what an index should do

```
XB_TIPO=6, XB_CONTEM = '#A1_FILIAL == xFilial("SA1")'
```

Filtering by branch in type 6 means every row is read and discarded. The right tool is **type 7** (upper/lower bounds), which restricts the SIX seek to the branch range.

```
XB_TIPO=7, XB_SEQ='01', XB_CONTEM = xFilial("SA1") + Replicate("Z",X3->X3_TAMANHO)
XB_TIPO=7, XB_SEQ='02', XB_CONTEM = xFilial("SA1")
```

## Specific-type function that does not set `VAR_IXB`

```advpl
User Function MyF3()
    Local cChoice := MyPickerDialog()
    Return !Empty(cChoice)   // VAR_IXB never assigned
EndFunc
```

**Symptom:** the type-5 expression evaluates against an undefined `VAR_IXB`, producing an empty return or a runtime error.

**Fix:** always assign `VAR_IXB` before returning `.T.`. If you need to cancel, return `.F.` without setting it.

```advpl
User Function MyF3()
    Local cChoice := MyPickerDialog()
    If !Empty(cChoice)
        VAR_IXB := cChoice
        Return .T.
    EndIf
Return .F.
```

## Setting `X3_F3` to a consulta whose table is not in SX2

The consulta exists, but its type-1 `XB_CONTEM` references a table missing from SX2 (often a customer-only table never registered properly).

**Symptom:** at runtime the lookup shows `Esta consulta não está cadastrada no SXB` or fails silently.

**Fix:** register the table in SX2 first (X2_NOME, X2_PATH, X2_SYSOBJ if applicable). Then create the consulta. Then wire `X3_F3`.

## Long expressions in `XB_CONTEM`

`XB_CONTEM` is `Char(250)`. Long SQL filters or AdvPL expressions that exceed the column truncate without warning.

**Fix:** wrap the body in a user function. The SXB row keeps a short `#U_MyFunc()` (or `@@` SQL inside a function that returns the literal). The truncation risk moves from data to code, where the compiler catches issues.

## Two consultas with the same `XB_ALIAS`

`XB_ALIAS` is the consulta key. Two different consultas with the same alias produce undefined behaviour — the engine picks one and ignores the other. This usually happens when a custom consulta is created without prefixing its alias.

**Detection:** `SELECT XB_ALIAS, COUNT(DISTINCT XB_DESCRI) FROM SXB WHERE XB_TIPO='1' GROUP BY XB_ALIAS HAVING COUNT(DISTINCT XB_DESCRI) > 1;`

**Fix:** rename one of them, then update every `SX3.X3_F3` that pointed to it.

## `Posicione` inside the consulta filter (type 6)

```
XB_TIPO=6, XB_CONTEM = 'Posicione("SBM",1,xFilial("SBM")+B1_GRUPO,"BM_BLOQUEIO") <> "1"'
```

`Posicione` runs for every row. With 10k products and 200 groups, that is 10k extra reads on SBM. The filter is correct but performance is catastrophic.

**Fix:** either move the filter to SQL with `@` (v12+, push down to the database where a join is cheap), or pre-load blocked groups into a static variable using `@#` (evaluated once) and filter in-memory.

```
XB_TIPO=6, XB_CONTEM = '@#U_LoadBlockedGroups()'
```

where `U_LoadBlockedGroups()` returns an `@`-prefixed SQL expression with the precomputed list.
