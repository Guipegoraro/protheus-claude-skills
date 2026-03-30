---
name: fwmsprinter-pdf
description: Use when creating PDF reports in ADVPL/TLPP using FWMSPrinter class - generating documents with boxes, grids, text alignment, headers, footers. Also use when debugging FWMSPrinter coordinate issues, text positioning problems, or PDF not displaying in WebApp.
---

# FWMSPrinter - PDF Report Generation

## Overview

FWMSPrinter is the Protheus class for generating PDF reports programmatically. Coordinates are in **points at 72 DPI**. A4 portrait = **620 x 876 points** (per TDN SetPaperSize docs). The `Say` method uses **baseline** positioning (text renders upward), while `SayAlign` uses **bounding box** positioning (text placed inside a rectangle).

## Constructor

```advpl
#INCLUDE "RPTDEF.CH"

// 12 parameters - positions 6-11 usually Nil
oPrint := FWMSPrinter():New(cFile, IMP_PDF, .F.,, .T.,,,,,,, .T.)
//                          1      2        3    4  5  6-11     12
// 1: cFile         - filename without extension (no special chars)
// 2: nDevice       - IMP_PDF (=6) for PDF output
// 3: lAdjustToLeg  - .F. ALWAYS for PDF (avoids Box/Line distortion)
// 4: cPathInServer - Nil (use cPathPDF property instead)
// 5: lDisableSetup - .T. (skip printer dialog)
// 6-11: Nil        - lTReport, oPrintSetup, cPrinter, lServer, lPDFAsPNG, lRaw
// 12: lViewPDF     - .T. to auto-open PDF after Print()
```

**CRITICAL**: Count commas carefully. Position 12 = `lViewPDF`. One missing comma shifts `.T.` to `lRaw` (position 11) causing unexpected behavior.

## Setup Sequence (mandatory order)

```advpl
oPrint:SetResolution(72)          // Always 72 (only supported value)
oPrint:SetPortrait()              // Or SetLandscape()
oPrint:SetPaperSize(DMPAPER_A4)   // A4 = 620x876pt
oPrint:SetMargin(30, 30, 30, 30)  // Left, Top, Right, Bottom
oPrint:cPathPDF := "C:\TEMP\"    // Directory for PDF output
oPrint:StartPage()
```

## Say vs SayAlign - Critical Difference

| Method | nRow means | Text renders | Use for |
|--------|-----------|-------------|---------|
| `Say(nRow, nCol, cText, oFont,, CLR_BLACK)` | **Baseline** (bottom of text) | Upward from nRow | Left-aligned text |
| `SayAlign(nRow, nCol, cText, oFont, nW, nH, CLR_BLACK, nAlignH, nAlignV)` | **Top of bounding box** | Inside the box | Centered/right text |

### Say - Baseline Positioning

```advpl
// To center text vertically in a 20pt box starting at nRow:
// Font ~9pt: baseline at nRow + 12 centers the text
oPrint:Say(nRow + 12, nCol, "Text", oFont,, CLR_BLACK)

// Parameters: nRow, nCol, cText, [oFont], [nWidth], [nClrText], [nAngle]
```

### SayAlign - Bounding Box Positioning

```advpl
oPrint:SayAlign(nRow + 5, nLeft, "Centered Title", oFont, nWidth, nHeight, CLR_BLACK, 2, 0)

// nAlignHorz: 0=Left, 1=Right, 2=Center, 3=Justified
// nAlignVert: 0=Center, 1=Top, 2=Bottom
```

## Box and Line

```advpl
// Box(nTop, nLeft, nBottom, nRight, cPenWidth)
oPrint:Box(nRow, nLeft, nRow + 25, nRight, "-2")  // "-2" = 0.2px (thicker)

// Line(nTop, nLeft, nBottom, nRight, nColor, cPenWidth)
oPrint:Line(nRow, nLeft, nRow, nRight,, "-1")      // Horizontal, "-1" = 0.1px (thin)
oPrint:Line(nRow, nCol, nRow + 20, nCol,, "-1")    // Vertical
```

**Pen widths**: `"-1"` = thin (0.1px), `"-2"` = medium (0.2px), `"-4"` = thick (0.4px)

## PDF Display and Output

```advpl
oPrint:EndPage()
oPrint:SetViewPDF(.T.)  // AFTER EndPage, BEFORE Print (matches ROM02E01/ROM06R01 pattern)
oPrint:Print()           // Generates PDF and opens it
```

**WebApp**: `SetViewPDF(.T.)` + `Print()` sends PDF to browser. Use `GetTempPath()` (no params) or explicit path like `"C:\TEMP\"`.

**Create directory if needed**:
```advpl
If !ExistDir(cPathPDF)
    MakeDir(cPathPDF)
EndIf
```

## Font Setup

```advpl
// TFont():New(cName, nWidth, nHeight, nWeight, lBold)
// nHeight is NEGATIVE (convention)
Local oFontTit  := TFont():New("Arial",, -14,, .T.)  // 14pt bold (titles)
Local oFontLbl  := TFont():New("Arial",, -10,, .T.)  // 10pt bold (labels)
Local oFontVal  := TFont():New("Arial",, -10,, .F.)  // 10pt normal (values)
Local oFontHdr  := TFont():New("Arial",, -9,,  .T.)  // 9pt bold (grid header)
Local oFontGrid := TFont():New("Arial",, -9,,  .F.)  // 9pt normal (grid data)

// ALWAYS FreeObj at the end:
FreeObj(oFontTit)
FreeObj(oFontLbl)
// ... all fonts + oPrint
```

## Grid Pattern (Box + Lines)

```advpl
// Grid header
oPrint:Box(nRow, nLeft, nRow + 20, nRight, "-2")
oPrint:Say(nRow + 12, nCol1, "COL1", oFontHdr,, CLR_BLACK)
oPrint:Say(nRow + 12, nCol2, "COL2", oFontHdr,, CLR_BLACK)
// Vertical separators
oPrint:Line(nRow, nCol2 - 5, nRow + 20, nCol2 - 5,, "-1")
nRow += 20

// Data rows
For nI := 1 To Len(aData)
    oPrint:Box(nRow, nLeft, nRow + nRowLine + 4, nRight, "-1")
    oPrint:Say(nRow + 12, nCol1, aData[nI][1], oFontGrid,, CLR_BLACK)
    oPrint:Say(nRow + 12, nCol2, aData[nI][2], oFontGrid,, CLR_BLACK)
    oPrint:Line(nRow, nCol2 - 5, nRow + nRowLine + 4, nCol2 - 5,, "-1")
    nRow += nRowLine + 4
Next nI
```

## Number Formatting for PDF

**DO NOT use `Transform` with `@E` picture** - it generates negative sign on integers. Use this helper:

```advpl
Static Function sfFmtNum(nVal, nDec)
    Local cRet
    Default nDec := 2
    If ValType(nVal) == "C"  // MsNewGetDados may return string
        nVal := Val(nVal)
    EndIf
    cRet := AllTrim(Str(nVal, 15, nDec))
    If nDec > 0
        cRet := StrTran(cRet, ".", ",")  // Brazilian format
    EndIf
Return cRet
```

## File Naming

```advpl
// Descriptive name without special chars
Local cFile := AllTrim(cPedido) + "_" + StrTran(AllTrim(cVendNom), " ", "_") + "_" + DToS(Date()) + "_report"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing comma in constructor (param shift) | Count: 5 params, then 6 commas, then `.T.` |
| `Say` text at top of box | Use `nRow + 12` offset (not `nRow + 2`) for 20pt box |
| `Transform(@E)` negative numbers | Use `Str()` + `StrTran(".",",")` helper |
| `SetViewPDF` before `StartPage` | Place AFTER `EndPage`, BEFORE `Print` |
| `GetTempPath(.F.)` in WebApp | Use `GetTempPath()` without params or explicit path |
| `lAdjustToLegacy = .T.` | Always `.F.` for PDF — avoids Box/Line distortion |
| Coordinates assume 595x842 (standard A4) | FWMSPrinter A4 = 620x876pt (per TDN) |
| Not calling `FreeObj` on fonts/printer | Memory leak on repeated calls |

## Layout Reference (A4 Portrait with SetMargin 30,30,30,30)

```
Page: 620 x 876 points
Margins: 30pt each side (SetMargin)
Usable area: 560 x 816 points
Coordinates relative to margin origin (0,0 = top-left of usable area)

Recommended layout variables:
  nLeft  := 20    // Internal left padding
  nRight := 540   // Internal right limit (560 - 20)
  nRowLine := 16  // Standard row height
  nRow starts at 40 for good top spacing
```
