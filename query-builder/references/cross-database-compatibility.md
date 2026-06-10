# Cross-Database Compatibility

Protheus supports **PostgreSQL**, **MSSQL Server**, and **Oracle**. All SQL code must be compatible with these three databases, or use the framework tools below to handle differences.

---

## ChangeQuery() — SQL Dialect Translation

`ChangeQuery(cQuery)` translates a SQL string to the active database dialect before execution. It handles syntax differences like `TOP` vs `LIMIT`, date functions, and string operations.

```tlpp
// GOOD: Use ChangeQuery() for cross-DB compatibility
Local cQuery := "SELECT TOP 10 A1_COD, A1_NOME FROM " + RetSQLName("SA1") + " SA1 "
cQuery += "WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_FILIAL = '" + FWxFilial("SA1") + "' "
cQuery := ChangeQuery(cQuery)  // Translates TOP to LIMIT on PostgreSQL, FETCH FIRST on Oracle
TCQuery cQuery New Alias cAlias
```

> **Tip:** BeginSQL/EndSQL (Embedded SQL) calls `ChangeQuery()` automatically unless `%noparser%` is specified.

---

## TCGetDB() — Runtime Database Detection

Use `TCGetDB()` when you need DB-specific logic that `ChangeQuery()` cannot handle:

```tlpp
Local cDB := TCGetDB() as Character  // Returns: "MSSQL", "ORACLE", or "POSTGRES"

Do Case
  Case cDB == "MSSQL"
    // MSSQL-specific syntax
  Case cDB == "ORACLE"
    // Oracle-specific syntax
  Case cDB == "POSTGRES"
    // PostgreSQL-specific syntax
EndCase
```

---

## DBAccess Macros Reference

These macros are used in SQL strings and Embedded SQL. DBAccess translates them per database:

| Macro         | Expansion                                              | Description                                         |
| ------------- | ------------------------------------------------------ | --------------------------------------------------- |
| `%nolock%`    | `WITH (NOLOCK)` on MSSQL; ignored on PostgreSQL/Oracle | Prevents lock escalation on read queries            |
| `%notDel%`    | `D_E_L_E_T_ = ' '`                                     | Soft-delete filter — used in BeginSQL/EndSQL        |
| `%table:XXX%` | `RetSqlName('XXX')`                                    | Physical table name — used in BeginSQL/EndSQL       |
| `%Order:XXX%` | `SqlOrder(XXX->(IndexKey()))`                          | Index-ordered column list — used in BeginSQL/EndSQL |

---

## Cross-Database Function Equivalents

| Operation         | ANSI / Cross-DB                         | MSSQL                                  | PostgreSQL                        | Oracle                                  |
| ----------------- | --------------------------------------- | -------------------------------------- | --------------------------------- | --------------------------------------- |
| Null coalescing   | `COALESCE(a, b)`                        | `ISNULL(a, b)`                         | `COALESCE(a, b)`                  | `NVL(a, b)`                             |
| String concat     | `CONCAT(a, b)`                          | `a + b`                                | `a \|\| b`                        | `a \|\| b`                              |
| Current date      | —                                       | `GETDATE()`                            | `CURRENT_DATE`                    | `SYSDATE`                               |
| Current timestamp | —                                       | `GETUTCDATE()`                         | `NOW()`                           | `SYSTIMESTAMP`                          |
| Row limiting      | `FETCH FIRST n ROWS ONLY`               | `TOP n`                                | `LIMIT n`                         | `FETCH FIRST n ROWS ONLY`               |
| Pagination        | `OFFSET x ROWS FETCH FIRST n ROWS ONLY` | `OFFSET x ROWS FETCH NEXT n ROWS ONLY` | `LIMIT n OFFSET x`                | `OFFSET x ROWS FETCH FIRST n ROWS ONLY` |
| Temp tables       | `FWTemporaryTable` (Protheus)           | `#temp_name`                           | `CREATE TEMPORARY TABLE`          | `CREATE GLOBAL TEMPORARY TABLE`         |
| Substring         | `SUBSTRING(s, start, len)`              | `SUBSTRING(s, start, len)`             | `SUBSTRING(s FROM start FOR len)` | `SUBSTR(s, start, len)`                 |
| Conditional       | `CASE WHEN ... THEN ... END`            | Same                                   | Same                              | Same                                    |

> **Protheus best practice:** Always use ANSI-compatible SQL (`COALESCE`, `CASE WHEN`, `CONCAT`, `FETCH FIRST`) or rely on `ChangeQuery()` to translate. Avoid DB-specific functions unless wrapped in a `TCGetDB()` check.
