# Examples

Concrete consultas you can adapt. Each example shows the full set of rows that must exist in SXB; in real life they are created through the **Configurador**, not via source.

## 1. Standard table lookup — SA1 (Clientes)

The most common case: a lookup over a regular table with two search indexes (code+store, name) and three columns visible.

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `1` | `01` | `DB` | `Cliente` | `SA1` |
| `SA1` | `2` | `01` | `01` | `Codigo+Loja` |  |
| `SA1` | `2` | `02` | `03` | `Nome` |  |
| `SA1` | `3` | `01` | `01` | `Cadastra Novo` | `01` |
| `SA1` | `4` | `01` | `01` | `Codigo` | `A1_COD` |
| `SA1` | `4` | `01` | `02` | `Loja` | `A1_LOJA` |
| `SA1` | `4` | `01` | `03` | `Nome` | `A1_NOME` |
| `SA1` | `4` | `02` | `04` | `Nome` | `A1_NOME` |
| `SA1` | `4` | `02` | `05` | `Codigo` | `A1_COD` |
| `SA1` | `5` | `01` |  |  | `SA1->A1_COD` |
| `SA1` | `5` | `02` |  |  | `SA1->A1_LOJA` |

Wired to a field via `SX3.X3_F3 = 'SA1'`. The receiving form must have the code field immediately followed by the store field.

## 2. Filtered lookup — SA1 by sales group

Same shape as example 1 but restricted to one sales group. The filter uses `#` so the variable is re-evaluated on every row.

Add to the SA1 rows above:

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1GRP` | `6` | `01` |  |  | `#If(Type('cGrupoCli')=='C',If(Empty(cGrupoCli),.T.,SA1->A1_GRPVEN==cGrupoCli),.T.)` |

For large datasets, push the filter to SQL (v12+):

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1GRP` | `6` | `01` |  |  | `@A1_GRPVEN = '0001' AND A1_MSBLQL <> '1'` |

The `@` marker tells the engine to inject the expression as an SQL `WHERE` clause.

## 3. Filtered lookup with a user function

When the filter expression exceeds 250 chars or needs runtime composition, delegate to a function:

```advpl
#include 'protheus.ch'

User Function FltCliVip()
    Local cSQL := "@A1_COD IN ('000001','000002','000003','000010','000011')"
    cSQL += " AND A1_RISCO < 'C'"
    cSQL += " AND A1_MSBLQL <> '1'"
Return cSQL
```

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1VIP` | `6` | `01` |  |  | `#U_FltCliVip()` |

`#` macro-executes the body, the body returns an `@`-prefixed SQL expression, the engine pushes it as SQL. Best of both worlds.

## 4. Insert/view override via tipo 9

Replace the default insert routine with a custom one:

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SA1` | `9` | `AC` |  |  | `ZCLI001` |

`ZCLI001` will be called for both insert (button "Cadastra Novo") and view actions. The consulta engine no longer consults `SX2.X2_SYSOBJ` / `X2_USROBJ` while this consulta is active.

This replaces the legacy pattern:

```
XB_TIPO=3, XB_CONTEM = '01#ZCLI001(,,3)#ZCLI001(,,2)'
```

Prefer tipo 9 for new code.

## 5. Specific lookup — wizard-style picker

Use Específica when there is no table behind the lookup: a tree, a file selector, a multi-source picker.

SXB rows:

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `ZFILE` | `1` | `01` | `RE` | `Importable file` |  |
| `ZFILE` | `2` | `01` | `01` |  | `U_ZF3File()` |
| `ZFILE` | `5` | `01` | `01` |  | `__cResult` |

Function:

```advpl
#include 'protheus.ch'

User Function ZF3File()
    Local lRet := .F.
    Public __cResult := cGetFile("Importable (*.csv)|*.csv", "Choose")

    If !Empty(__cResult)
        __cResult := Alltrim(StrTran(StrTran(__cResult, Chr(13)), Chr(10)))
        VAR_IXB   := __cResult
        lRet      := .T.
    EndIf
Return lRet
```

Key points:

- The function returns `.T.` to confirm, `.F.` to cancel.
- `VAR_IXB` carries the value the engine writes back via the type-5 expression. Setting it inside the function is the standard contract.
- A `Public` variable (`__cResult`) is used because the type-5 expression must reference something visible at evaluation time.

## 6. Cross-table lookup — return via `Posicione`

When the lookup is over table A but the receiving field needs a value from a related table B:

| `XB_ALIAS` | `XB_TIPO` | `XB_SEQ` | `XB_COLUNA` | `XB_DESCRI` | `XB_CONTEM` |
| --- | --- | --- | --- | --- | --- |
| `SB1POS` | `1` | `01` | `DB` | `Produto com descrição` | `SB1` |
| `SB1POS` | `2` | `01` | `01` | `Codigo` |  |
| `SB1POS` | `4` | `01` | `01` | `Codigo` | `B1_COD` |
| `SB1POS` | `4` | `01` | `02` | `Descrição` | `B1_DESC` |
| `SB1POS` | `4` | `01` | `03` | `Grupo` | `B1_GRUPO` |
| `SB1POS` | `4` | `01` | `04` | `Grupo descrição` | `Posicione("SBM",1,xFilial("SBM")+B1_GRUPO,"BM_DESC")` |
| `SB1POS` | `5` | `01` |  |  | `SB1->B1_COD` |

The `Posicione` call inside type-4 column 4 is evaluated per row. Use `GetSx3Cache` if it must repeat for many records, to avoid hot-path SX3 reads.

## 7. Wiring a custom field to a lookup

Field `Z1_CLIENTE` should F3 to SA1 with code+store as return:

1. Register the field in SX3 via the Configurador.
2. Set `Z1_CLIENTE.X3_F3 = 'SA1'`.
3. Place the next field (e.g. `Z1_LOJA`) immediately after `Z1_CLIENTE` in the form's tab order.

The consulta `SA1` already returns code + store, so two fields are populated on selection. No SXB change needed — reuse the standard one.

If you need an alternative behaviour (e.g. only customers in a specific group), do **not** alter the standard `SA1` consulta. Create a new `XB_ALIAS` (`ZSA1G1`, `SA1VIP`) and wire that to `X3_F3` instead.
