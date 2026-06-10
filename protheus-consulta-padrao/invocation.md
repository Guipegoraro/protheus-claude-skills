# Invocation

## Contents

- Field-level wiring via `SX3.X3_F3`
- Manual invocation: `ConPad1`
- MVC views: `FWLookUp`
- Workflow/ECM: `FWWFLookUp`
- Helper functions

## Field-level wiring via `SX3.X3_F3`

A field gets a magnifying-glass icon (and the F3 keystroke) by carrying the consulta code in `SX3.X3_F3`.

```sql
SELECT X3_CAMPO, X3_F3, X3_TITULO
  FROM SX3
 WHERE X3_CAMPO IN ('C5_CLIENTE','D1_COD');
```

```
X3_CAMPO     X3_F3   X3_TITULO
C5_CLIENTE   SA1     Cliente
D1_COD       SB1     Produto
```

- `X3_F3` holds the `XB_ALIAS` of the consulta to invoke.
- This wiring is data, not code — set it via the **Configurador**, not via `RecLock("SX3")` in a font.
- A field with `X3_F3` empty has no F3 lookup, even if a matching consulta exists in SXB.
- The same consulta can be wired to many fields (`SA1` is wired to `C5_CLIENTE`, `D1_CLIENTE`, `E1_CLIENTE`, etc.).

## Manual invocation: `ConPad1`

`ConPad1` opens the standard lookup modal programmatically. Use it inside an entry point, a validation, or a `Specifica`-type function.

**Signature** (positional, all nillable):

```
ConPad1( uPar1, uPar2, uPar3, cAlias, cCampoRet, uPar6, lOnlyView, cVar, uPar9, uContent )
```

| Position | Name | Purpose |
| --- | --- | --- |
| 4 | `cAlias` | `XB_ALIAS` of the consulta to open (the only commonly used parameter). |
| 5 | `cCampoRet` | Field that will receive the return. If empty, the current `ReadVar()` is used. |
| 7 | `lOnlyView` | `.T.` opens in read-only mode (no insert/edit buttons). |
| 8 | `cVar` | Variable name receiving the return, when there is no `ReadVar()` context. |

The other positions are legacy reserved slots. Pass `Nil` to skip them.

**Typical usage inside a Specifica's tipo-2 function**:

```advpl
Function MyF3()
    Local lRet := ConPad1(Nil, Nil, Nil, "SA1", Nil, Nil, .T., Nil)
    // Selected SA1 record is positioned; project what you want
    VAR_IXB := SA1->A1_COD
    Return lRet
EndFunc
```

`VAR_IXB` is the public variable the SXB engine reads after the function returns. The type-5 row evaluates against it.

**Validating an alias before opening** — pattern used in standard sources:

```advpl
Function A926FIL()
    Local cAliasSXB := A926RetTab()  // resolves which table to look up
    Return ConPad1(Nil, Nil, Nil, cAliasSXB)
EndFunc
```

## MVC views: `FWLookUp`

MVC views (`FWFormView`) hook lookups via the model's field metadata. The `X3_F3` on the field is enough — the framework wires the F3 automatically.

When the lookup needs runtime context (e.g. a filter that depends on another field on the same form), override the lookup at view level with `FWLookUp`:

```advpl
oView:AddIncrementField("VIEW_DETAIL", "D2_COD")
// Lookup is automatic via X3_F3 on D2_COD
```

For Smart View / web parameter lookups, the framework calls `GenericLookupService` against your `XB_ALIAS`. That service only accepts **DB consultas** whose type-5 return is one of:

- A plain SX3 field (`A1_COD`)
- A concatenation of SX3 fields (`A1_COD + A1_LOJA`)
- A `Posicione(...)` expression

Anything else — functions, `IF`/`IIF`, `&`, `@`, `#` markers — is silently ignored. If your consulta needs Smart View / REST exposure, keep type 5 boring.

## Workflow/ECM: `FWWFLookUp`

For ECM workflow entities (users/groups), use the dedicated function:

```
FWWFLookUp( nType, bRetFunc ) → lRet
```

- `nType`: `1` = group, `2` = user.
- `bRetFunc`: codeblock invoked with the selection. Use it to project the picked id/name back into your form.

This is independent of SXB — it queries the ECM entity store, not the consulta dictionary.

## Helper functions

| Function | Purpose |
| --- | --- |
| `ConPad1` | Opens a DB-type consulta modally. Standard programmatic entry point. |
| `FWLookUp` | MVC view-level lookup wiring. |
| `FWWFLookUp` | ECM workflow user/group picker. |
| `XBDescri` | Returns the localised description of the consulta currently positioned in SXB. |
| `Posicione` | Field projection at type-5 time: `Posicione("SB1", 1, xFilial("SB1")+SA1->A1_PADRAO, "B1_DESC")`. Safe for `GenericLookupService`. |
| `GetSx3Cache` | Caches SX3 reads in-process. Use it inside type-5 expressions that consult SX3 to avoid hot-path reads. |

## Caller-side: receiving multiple returns

A consulta with N type-5 rows fills the focused field plus the next N−1 fields in the form's tab order. This is implicit and brittle:

- The destination form must place the receiving fields in the **exact order** the consulta returns them.
- If a field between the receivers has `When` returning `.F.`, the engine skips it; the next enabled field receives the value. This breaks layout assumptions.
- For MsGetDB / TGetDados grids, the receiving columns must be visible and editable.

When the calling site cannot be guaranteed to match, prefer a single return and let the form's `Trigger` (SX7) propagate dependent values from the selected key.
