# Ler um DOCX como imagem

Mecânica dos passos 3 (corpus) e 7 (verificação final) da [`SKILL.md`](SKILL.md). Windows,
Word instalado, PowerShell 7.

## DOCX para PDF via Word COM

`SaveAs` com `[ref]` falha no PowerShell 7; usar `ExportAsFixedFormat`. Arquivo aberto no Word
do usuário trava o `Open`: avisar e pedir para fechar. `Close`/`Quit` em `finally` para não
deixar `WINWORD.EXE` órfão.

```powershell
$word = New-Object -ComObject Word.Application; $word.Visible = $false
try {
  $doc = $word.Documents.Open($docx, $false, $somenteLeitura)
  if (-not $somenteLeitura) {                          # documento gerado: calcula o sumário
    $doc.TablesOfContents.Item(1).Update() | Out-Null  # e grava no próprio DOCX
    $doc.Save()
  }
  $doc.ExportAsFixedFormat($pdf, 17)                   # 17 = wdExportFormatPDF
} finally { if ($doc) { $doc.Close($false) }; $word.Quit() }
```

Corpus: `$somenteLeitura = $true`. Documento gerado: `$false`, e é isto que substitui o F9 do
leitor; toda inserção de figura desloca páginas, então o sumário só é confiável depois desta
exportação. Se o Word imprimir o código do campo em vez do sumário:
`$word.ActiveWindow.View.ShowFieldCodes = $false`.

## PDF para PNG

poppler (`winget install oschwartz10612.Poppler`), chamado pelo caminho completo porque o PATH
novo não aparece na mesma sessão:

```powershell
$pop = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\oschwartz10612.Poppler_*\poppler-*\Library\bin\pdftoppm.exe")[0].FullName
& $pop -png -r 100 $pdf $prefixo
& ($pop -replace 'pdftoppm','pdfinfo') $pdf          # "Page size: 595 x 842 pts (A4)"
```

Sufixo de página: 1 dígito até 9 páginas (`-1.png`), 2 dígitos a partir de 10 (`-01.png`).

## Ler

Nomes com acento podem vir em NFD e o Read falha; normalizar para ASCII antes:
`$n.Normalize([Text.NormalizationForm]::FormD) -replace '\p{Mn}',''`. Ler os PNG com o Read;
na verificação final, todas as páginas.
