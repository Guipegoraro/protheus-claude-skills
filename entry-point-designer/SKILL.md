---
name: entry-point-designer
description: "Design and document Protheus Entry Points (Pontos de Entrada) with proper User Function signatures, PARAMIXB parameter layouts, return value specifications, and standard documentation format. Use when user says 'create entry point', 'ponto de entrada', 'PARAMIXB', 'User Function hook'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Engenharia Protheus - Dados & DevOps
  author: Melkz Siqueira
  version: '4.1.0'
  category: Code Generation
---

# Protheus Entry Point Designer

## Overview

Design, implement, and document Protheus Entry Points (Pontos de Entrada). Entry Points are the standard extensibility mechanism in TOTVS Protheus, allowing customization of standard ERP routines without modifying the original source code.

## When to Use

Use this skill when:

- Creating a new Entry Point to customize standard Protheus behavior
- Documenting existing Entry Points
- Designing the PARAMIXB interface for custom Entry Points
- Migrating legacy Entry Points to TLPP

---

## Entry Point Fundamentals

### How Entry Points Work

1. A **standard TOTVS routine** (e.g., MATA010, FINA010) calls `ExistBlock("PE_NAME")` at predefined extension points
2. If a `User Function` with the matching name exists in the RPO, it is executed
3. The standard routine passes parameters via the `PARAMIXB` array (Private variable)
4. The Entry Point returns a value that influences the standard routine's behavior

### Naming Convention

- Entry Point names are defined by TOTVS in the standard routines
- They typically follow: `<routine_context>` or `<module><action>` pattern
- Examples: `MT010INC` (MATA010 inclusion), `A010TOK` (SA1 inclusion OK), `FA080BUT` (FATA080 buttons)

---

## Entry Point Template (AdvPL)

```advpl
#include "totvs.ch"

//-------------------------------------------------------------------
// Entry Point: {PE_NAME}
// Routine:     {Standard routine name} ({Module})
// Description: {What this entry point does}
// Trigger:     {When this EP is called in the standard flow}
//-------------------------------------------------------------------
// PARAMIXB Layout:
//   [1] - {Type} - {Description}
//   [2] - {Type} - {Description}
//   [3] - {Type} - {Description}
//-------------------------------------------------------------------
// Return: {Type} - {Description of what the return value does}
//   .T. = {effect when true}
//   .F. = {effect when false}
//   (or describe the return structure)
//-------------------------------------------------------------------
User Function {PE_NAME}()
  Local aParam   := PARAMIXB
  Local xParam1  := Nil
  Local xParam2  := Nil
  Local lRet     := .T.

  // Defensive validation of PARAMIXB
  If Type("PARAMIXB") == "A" .And. Len(PARAMIXB) >= 2
    xParam1 := PARAMIXB[1]
    xParam2 := PARAMIXB[2]
  Else
    // PARAMIXB not available or insufficient parameters
    Return lRet
  EndIf

  // Business logic
  // ...

Return lRet
```

## Entry Point Template (TLPP)

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

Namespace custom.entrypoints.{module}

//-------------------------------------------------------------------
// Entry Point: {PE_NAME}
// Routine:     {Standard routine name} ({Module})
// Description: {What this entry point does}
// Trigger:     {When this EP is called in the standard flow}
//-------------------------------------------------------------------
// PARAMIXB Layout:
//   [1] - {Type} - {Description}
//   [2] - {Type} - {Description}
//   [3] - {Type} - {Description}
//-------------------------------------------------------------------
// Return: {Type} - {Description of what the return value does}
//-------------------------------------------------------------------
User Function {PE_NAME}() as {ReturnType}
  Local aParam  as Array
  Local xParam1 as {Type}
  Local xParam2 as {Type}
  Local lRet    := .T. as Logical

  // Defensive validation of PARAMIXB
  If Type("PARAMIXB") <> "A" .Or. Len(PARAMIXB) < 2
    Return lRet
  EndIf

  aParam  := PARAMIXB
  xParam1 := aParam[1]
  xParam2 := aParam[2]

  // Business logic
  Try
    lRet := ProcessEntryPoint(xParam1, xParam2)
  Catch oError
    FWLogMsg("ERROR", , "EP", "{PE_NAME}", , "01", oError:Description, 0, 0, {})
    lRet := .T.  // fail-safe: don't block standard routine
  EndTry

Return lRet

Static Function ProcessEntryPoint(xParam1 as {Type}, xParam2 as {Type}) as Logical
  // Focused business logic here
Return .T.
```

---

## Common Entry Point Return Types

| Return Type         | Typical Use                                                         |
| ------------------- | ------------------------------------------------------------------- |
| `Logical (.T./.F.)` | Approve/reject an action (e.g., allow inclusion, validate deletion) |
| `Array`             | Return modified data (e.g., additional fields, modified grid data)  |
| `Character`         | Return modified query, filter expression, or message                |
| `Numeric`           | Return a calculated value                                           |
| `Nil`               | Entry Point has no return effect (side-effect only)                 |

---

## PARAMIXB Documentation Format

Document each PARAMIXB parameter in this standard table format:

| Position | Type      | Description                              | Example Value |
| -------- | --------- | ---------------------------------------- | ------------- |
| [1]      | Character | Customer code being processed            | "000001"      |
| [2]      | Character | Store code                               | "01"          |
| [3]      | Logical   | Indicates if it's an inclusion operation | .T.           |
| [4]      | Object    | FWFormModel object (MVC screens)         | oModel        |

---

## Entry Point Design Checklist

### Interface Design

- [ ] PARAMIXB layout is fully documented (position, type, description, example)
- [ ] Return type and its effect on the standard routine are documented
- [ ] The entry point trigger moment is clearly identified (before validation, after save, during grid processing, etc.)

### Defensive Programming

- [ ] PARAMIXB existence is checked (`Type("PARAMIXB") == "A"`)
- [ ] PARAMIXB length is validated before accessing elements
- [ ] Parameter types are validated before use
- [ ] Error handling prevents the entry point from crashing the standard routine
- [ ] Default return value is "safe" (doesn't block the standard flow)

### Code Quality

- [ ] Business logic is extracted to `Static Function` helpers
- [ ] Variables use `Local` scope (not `Private`)
- [ ] TLPP type annotations are present (if `.tlpp` file)
- [ ] Header comment block includes: PE name, routine, description, PARAMIXB layout, return type

### Testing

- [ ] Entry Point tested with all expected PARAMIXB variations
- [ ] Tested with empty/nil PARAMIXB (defensive case)
- [ ] Return values verified in all code paths
- [ ] Side effects (database writes, API calls) tested independently

### SonarQube Compliance

- [ ] Error handling uses `Try-Catch` exclusively — never use `ErrorBlock` in Entry Points
- [ ] No `StaticCall()` — use `FWLoadModel()`, `FWLoadMenuDef()`, or namespace-based calls
- [ ] Entry Points triggered during transactions (Before Save, After Save) must NOT call UI functions (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`)
- [ ] No assignment to `__cUserID` or `cEmpAnt`
- [ ] No `IIF()` — use `If/Else/EndIf` blocks
- [ ] `GetMV()` / `ExistBlock()` results cached before use in loops
- [ ] Logging via `FWLogMsg()`, not `ConOut()`

> Refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

---

## Common Entry Point Categories

| Category              | Example EPs            | Typical PARAMIXB                |
| --------------------- | ---------------------- | ------------------------------- | ------------------------------------------------------------ |
| **Before Validation** | `MT010INC`, `FA080BUT` | Form fields, model object       |
| **After Validation**  | `A010TOK`              | Validation result, field values |
| **Before Save**       | `MT100GRV`             | Header/item data arrays         | _Executes inside transaction — never call UI functions here_ |
| **After Save**        | `MT100APP`             | Document number, saved data     | _Executes inside transaction — never call UI functions here_ |
| **Before Delete**     | `MT010DEL`             | Record data                     |
| **Grid Processing**   | `MT100LIN`             | Line number, grid data          |
| **Report Filter**     | `MT580FIL`             | Filter expression               |
| **Menu Extension**    | `FA080BUT`             | Button array                    |

---

## Troubleshooting

- **Entry Point not triggered**: The function name must match the expected EP name exactly (case-sensitive). Verify the EP exists for the standard routine version in use.
- **PARAMIXB is NIL or empty**: Not all Entry Points pass parameters. Check TDN documentation for the specific EP to confirm which parameters are available and their positions.
- **Entry Point crashes the standard routine**: Always wrap EP logic in `Try-Catch`. An unhandled error in an EP propagates up and can abort the entire standard operation.
- **Return value ignored**: Some EPs require a specific return type (e.g., `.T.`/`.F.` for validation EPs). If the return type is wrong, the standard routine may ignore it silently.
- **EP works in one module but not another**: Entry Points are module-specific. An EP registered for SIGAFIN will not fire in SIGAFAT even if the function name is identical.

