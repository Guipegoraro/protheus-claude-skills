# Query Patterns and Code Examples

Complete AdvPL/TLPP code templates for each Protheus query pattern. Use these as starting points and adapt to the specific table, fields, and business logic.

---

## Pattern 1: Simple Select with Workarea

Use **Workarea access** when:

- Navigating records sequentially by an existing index
- Performing record-by-record operations (locking, updating)
- The table has a suitable index for the access pattern

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Static Function GetCustomerName(cCustCode as Character) as Character
  Local cName := "" as Character
  Local aArea := SA1->(GetArea()) as Array

  DbSelectArea("SA1")
  SA1->(DbSetOrder(1))  // Index 1: A1_FILIAL + A1_COD + A1_LOJA

  If SA1->(DbSeek(FWxFilial("SA1") + cCustCode))
    cName := AllTrim(SA1->A1_NOME)
  EndIf

  SA1->(RestArea(aArea))
Return cName
```

---

## Pattern 2: Simple Select with Embedded SQL (TCQuery)

Use **Embedded SQL** when:

- Performing complex joins across multiple tables
- Using aggregation functions (SUM, COUNT, AVG, MAX, MIN)
- The query doesn't map cleanly to a single index seek
- Reading large datasets where Workarea would be too slow

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Static Function GetCustomerBalance(cCustCode as Character) as Numeric
  Local nBalance := 0 as Numeric
  Local cAlias   := GetNextAlias() as Character
  Local oStatement := FWPreparedStatement():New() as Object

  oStatement:SetQuery("SELECT SUM(E1_SALDO) AS BALANCE " + ;
    "FROM " + RetSQLName("SE1") + " SE1 " + ;
    "WHERE SE1.D_E_L_E_T_ = ' ' " + ;
    "AND SE1.E1_FILIAL = ? " + ;
    "AND SE1.E1_CLIENTE = ? " + ;
    "AND SE1.E1_SALDO > 0 ")
  oStatement:SetString(1, FWxFilial("SE1"))
  oStatement:SetString(2, cCustCode)

  DBUseArea(.T., "TOPCONN", TCGenQry(,, oStatement:GetFixQuery()), cAlias, .F., .T.)

  If !(cAlias)->(Eof())
    nBalance := (cAlias)->BALANCE
  EndIf

  (cAlias)->(DBCloseArea())
Return nBalance
```

---

## Pattern 3: Multi-Table Join

```tlpp
Static Function GetInvoiceDetails(cInvDoc as Character) as Array
  Local cQuery := "" as Character
  Local cAlias := GetNextAlias() as Character
  Local aResult := {} as Array

  cQuery := "SELECT SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_EMISSAO, "
  cQuery += "       SD2.D2_COD, SD2.D2_QUANT, SD2.D2_TOTAL, "
  cQuery += "       SB1.B1_DESC "
  cQuery += "FROM " + RetSQLName("SF2") + " SF2 "
  cQuery += "INNER JOIN " + RetSQLName("SD2") + " SD2 "
  cQuery += "  ON SD2.D_E_L_E_T_ = ' ' "
  cQuery += "  AND SD2.D2_FILIAL = SF2.F2_FILIAL "
  cQuery += "  AND SD2.D2_DOC = SF2.F2_DOC "
  cQuery += "  AND SD2.D2_SERIE = SF2.F2_SERIE "
  cQuery += "INNER JOIN " + RetSQLName("SB1") + " SB1 "
  cQuery += "  ON SB1.D_E_L_E_T_ = ' ' "
  cQuery += "  AND SB1.B1_FILIAL = '" + FWxFilial("SB1") + "' "
  cQuery += "  AND SB1.B1_COD = SD2.D2_COD "
  cQuery += "WHERE SF2.D_E_L_E_T_ = ' ' "
  cQuery += "AND SF2.F2_FILIAL = '" + FWxFilial("SF2") + "' "
  cQuery += "AND SF2.F2_DOC = ? "

  Local oStatement := FWPreparedStatement():New() as Object
  oStatement:SetQuery(cQuery)
  oStatement:SetString(1, cInvDoc)

  DBUseArea(.T., "TOPCONN", TCGenQry(,, oStatement:GetFixQuery()), cAlias, .F., .T.)

  While !(cAlias)->(Eof())
    aAdd(aResult, { ;
      AllTrim((cAlias)->F2_DOC),   ;
      AllTrim((cAlias)->D2_COD),   ;
      (cAlias)->D2_QUANT,          ;
      (cAlias)->D2_TOTAL,          ;
      AllTrim((cAlias)->B1_DESC)   ;
    })
    (cAlias)->(DBSkip())
  EndDo

  (cAlias)->(DBCloseArea())
Return aResult
```

---

## Pattern 4: INSERT/UPDATE via TCSqlExec

Use `TCSqlExec` for direct SQL operations. Prefer Workarea `RecLock`/`MsUnlock` for standard Protheus operations since they trigger data dictionary validations and events.

```tlpp
// Direct SQL update — use FWPreparedStatement for safety
Static Function UpdateCustomerFlag(cCustCode as Character, cFlag as Character) as Logical
  Local nResult := 0 as Numeric
  Local oStatement := FWPreparedStatement():New() as Object

  oStatement:SetQuery("UPDATE " + RetSQLName("SA1") + " " + ;
    "SET A1_XFLAG = ? " + ;
    "WHERE D_E_L_E_T_ = ' ' " + ;
    "AND A1_FILIAL = ? " + ;
    "AND A1_COD = ? ")
  oStatement:SetString(1, cFlag)
  oStatement:SetString(2, FWxFilial("SA1"))
  oStatement:SetString(3, cCustCode)

  nResult := TCSqlExec(oStatement:GetFixQuery())
Return (nResult == 0)
```

---

## Pattern 5: Counting Records

```tlpp
Static Function CountActiveCustomers() as Numeric
  Local cQuery := "" as Character
  Local cAlias := GetNextAlias() as Character
  Local nCount := 0 as Numeric

  cQuery := "SELECT COUNT(*) AS TOTAL "
  cQuery += "FROM " + RetSQLName("SA1") + " SA1 "
  cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' "
  cQuery += "AND SA1.A1_FILIAL = '" + FWxFilial("SA1") + "' "
  cQuery += "AND SA1.A1_MSBLQL <> '1' "  // Not blocked

  DBUseArea(.T., "TOPCONN", TCGenQry(,, cQuery), cAlias, .F., .T.)

  If !(cAlias)->(Eof())
    nCount := (cAlias)->TOTAL
  EndIf

  (cAlias)->(DBCloseArea())
Return nCount
```

---

## SQL Injection Prevention — Detailed Examples

**Never concatenate user input directly into SQL strings.** Use `FWPreparedStatement` to parameterize all dynamic values:

```tlpp
// DANGEROUS: SQL injection vulnerability
// cQuery += "AND A1_COD = '" + cUserInput + "' "

// SAFE: Parameterized via FWPreparedStatement
Local oStatement := FWPreparedStatement():New() as Object
oStatement:SetQuery("SELECT A1_COD, A1_NOME FROM " + RetSQLName("SA1") + " SA1 " + ;
  "WHERE SA1.D_E_L_E_T_ = ' ' " + ;
  "AND SA1.A1_FILIAL = ? " + ;
  "AND SA1.A1_COD = ? ")
oStatement:SetString(1, FWxFilial("SA1"))
oStatement:SetString(2, cUserInput)

DBUseArea(.T., "TOPCONN", TCGenQry(,, oStatement:GetFixQuery()), cAlias, .F., .T.)
```

For LIKE clauses:

```tlpp
// SAFE: Parameterized LIKE — prepend/append % on the AdvPL side for cross-DB safety
// (MSSQL uses + for concat, PostgreSQL/Oracle use || — avoid both in SQL)
Local cSearchParam := "%" + cSearch + "%" as Character

oStatement:SetQuery("SELECT A1_COD, A1_NOME FROM " + RetSQLName("SA1") + " SA1 " + ;
  "WHERE SA1.D_E_L_E_T_ = ' ' " + ;
  "AND SA1.A1_FILIAL = ? " + ;
  "AND SA1.A1_NOME LIKE ? ")
oStatement:SetString(1, FWxFilial("SA1"))
oStatement:SetString(2, cSearchParam)
```
