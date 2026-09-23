param(
    [Parameter(Position=0)][string[]]$Codigos = @(),  # ex: MATR320,FINR130  (ou use -Lista)
    [string]$Lista      = "",                          # arquivo texto: 1 codigo por linha (# = comentario)
    [string]$Dest       = "",                          # pasta destino dos z*.prw (default: pasta atual)
    [string[]]$Fontes   = @(),                         # raizes de busca do .prx (default: Desktop\padrao)
    [string]$IncludeDir = "",                          # \include do Protheus (copia do .ch + checagem)
    [string]$Prefix     = "z",
    [switch]$DryRun,                                   # so dry-run do engine; nao grava nada no destino
    [switch]$Force,                                    # sobrescreve z<cod>.prw ja existente
    [string]$LogDir     = ""                           # default: %TEMP%\refazer-lote-<stamp>
)

# ============================================================================
#  Wrapper de LOTE da skill "refazer-relatorio-classico".
#
#  Roda os passos 1-5 da SKILL.md (localizar fonte -> copiar como z<cod>.prw ->
#  dry-run -> engine -> copiar .ch -> validar) para N relatorios de uma vez, e
#  emite UMA LINHA por relatorio.
#
#  Motivo de existir: os passos 1-5 sao 100% mecanicos. Rodar um a um gasta
#  contexto/atencao lendo saida repetida; o que interessa e a tabela final e o
#  detalhe SO dos que falharam (que fica em $LogDir, um arquivo por relatorio).
#
#  NAO cobre (continua sendo trabalho caso a caso, ver SKILL.md):
#    - colisao de 10 chars  -> secao 3   (o engine recusa gravar; wrapper marca)
#    - shim PARAMIXB        -> secao 7.1 (wrapper marca "PARAMIXB?" por heuristica)
#    - compilar / testar    -> secao 7   (unica prova 100%)
# ============================================================================

$ErrorActionPreference = 'Stop'

# --- resolucao de entradas ---------------------------------------------------
if ($Lista) {
    if (-not (Test-Path -LiteralPath $Lista)) { Write-Error "Lista nao encontrada: $Lista"; exit 1 }
    $Codigos += Get-Content -LiteralPath $Lista |
                ForEach-Object { ($_ -split '#')[0].Trim() } |
                Where-Object   { $_ -ne '' }
}
$Codigos = $Codigos | ForEach-Object { $_.Trim().ToUpper() } | Where-Object { $_ } | Select-Object -Unique
if ($Codigos.Count -eq 0) { Write-Error "Informe -Codigos MATR320,FINR130 ou -Lista <arquivo>"; exit 1 }

if (-not $Dest) { $Dest = (Get-Location).Path }
if (-not (Test-Path -LiteralPath $Dest)) { Write-Error "Destino nao existe: $Dest"; exit 1 }
$Dest = (Resolve-Path -LiteralPath $Dest).Path

if ($Fontes.Count -eq 0) {
    # Ordem importa: "Fontes Relatorios Central TOTVS" traz o .ch junto e costuma
    # ser a versao mais nova do mesmo .prx -- preferir sempre essa raiz.
    $Fontes = @(
        (Join-Path $env:USERPROFILE 'Desktop\padrao\Fontes Relatorios Central TOTVS'),
        (Join-Path $env:USERPROFILE 'Desktop\padrao\Fontes')
    )
}
$Fontes = $Fontes | Where-Object { Test-Path -LiteralPath $_ }
if ($Fontes.Count -eq 0) { Write-Error "Nenhuma raiz de fontes valida. Passe -Fontes <pasta>."; exit 1 }

if ($IncludeDir -and -not (Test-Path -LiteralPath $IncludeDir)) {
    Write-Error "IncludeDir nao existe: $IncludeDir"; exit 1
}

if (-not $LogDir) {
    $LogDir = Join-Path $env:TEMP ("refazer-lote-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$engine = Join-Path $PSScriptRoot 'refazer-relatorio.ps1'
$valida = Join-Path $PSScriptRoot 'validar-relatorio.ps1'
foreach ($s in @($engine, $valida)) {
    if (-not (Test-Path -LiteralPath $s)) { Write-Error "Script da skill nao encontrado: $s"; exit 1 }
}

# Host do PowerShell para rodar os scripts filhos. Processo separado de proposito:
# so assim $LASTEXITCODE e confiavel (o engine so faz "exit 2" no erro; dot-source
# manteria o exit code da chamada anterior e o lote leria falha onde nao houve).
$psExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $psExe) { $psExe = (Get-Command powershell -ErrorAction SilentlyContinue).Source }
if (-not $psExe) { Write-Error "Nao achei pwsh nem powershell no PATH."; exit 1 }

function Invoke-Filho {
    # NAO renomear $ChildArgs para $Args: $Args e variavel automatica do PowerShell
    # e o splat sai vazio (o filho reclama de -Path faltando).
    param([string]$Script, [string[]]$ChildArgs, [string]$LogFile)
    $out = & $psExe -NoProfile -NonInteractive -File $Script @ChildArgs 2>&1
    $rc  = $LASTEXITCODE
    $txt = ($out | Out-String)
    Set-Content -LiteralPath $LogFile -Value $txt -Encoding UTF8
    [pscustomobject]@{ Rc = $rc; Txt = $txt }
}

function Get-Valor {
    # Le "<Rotulo> : <valor>" da saida do engine. $Rotulo e regex (escapar '.' do
    # rotulo 'Trava VldDescRel rem.'). Devolve $Default se o rotulo nao aparecer.
    param([string]$Txt, [string]$Rotulo, [string]$Default = '')
    $m = [regex]::Match($Txt, ('(?im)^\s*' + $Rotulo + '\s*:\s*(\S+)'))
    if ($m.Success) { $m.Groups[1].Value } else { $Default }
}

"Lote: $($Codigos.Count) relatorio(s) | Destino: $Dest | Logs: $LogDir"
if ($DryRun) { "MODO DRY-RUN: nada sera gravado no destino." }
""

$res = @()

foreach ($cod in $Codigos) {
    $r = [pscustomobject]@{
        CODIGO     = $cod
        FONTE      = ''
        FUNCS      = ''
        TRAVA      = ''
        STATICCALL = ''
        ENGINE     = ''
        CH         = ''
        VALIDADOR  = ''
        'PARAMIXB?'= ''
        OBS        = ''
    }

    # --- 1. localizar o .prx/.prw padrao ------------------------------------
    $hit = $null
    foreach ($raiz in $Fontes) {
        foreach ($ext in @('prx','prw')) {
            $hit = Get-ChildItem -LiteralPath $raiz -Recurse -File -Filter "$cod.$ext" -ErrorAction SilentlyContinue |
                   Select-Object -First 1
            if ($hit) { break }
        }
        if ($hit) { break }
    }
    if (-not $hit) {
        $r.FONTE = 'NAO-ACHOU'; $r.OBS = 'fonte ausente nas raizes'; $res += $r; continue
    }
    $r.FONTE = $hit.Directory.Name

    # --- 2. copiar como z<cod>.prw ------------------------------------------
    $alvo = Join-Path $Dest ("$Prefix$cod.prw".ToLower())
    if ((Test-Path -LiteralPath $alvo) -and -not $Force -and -not $DryRun) {
        $r.ENGINE = 'JA-EXISTE'; $r.OBS = 'use -Force p/ sobrescrever'; $res += $r; continue
    }

    $trabalho = if ($DryRun) { Join-Path $LogDir ("$Prefix$cod.prw".ToLower()) } else { $alvo }
    [System.IO.File]::Copy($hit.FullName, $trabalho, $true)   # byte-a-byte: preserva CP1252/box-art e CRLF

    # --- 3a. dry-run do engine (funcoes, trava, StaticCall, colisao) --------
    $d = Invoke-Filho -Script $engine -ChildArgs @('-Path', $trabalho, '-Prefix', $Prefix, '-DryRun') `
                      -LogFile (Join-Path $LogDir "$cod.1-dryrun.txt")

    # Parsing ancorado no ROTULO + valor do engine. Nao usar "match do nome do rotulo"
    # como sinal: o engine imprime "Colisao 10-char : False" mesmo quando NAO ha
    # colisao -- casar so o texto marcaria todo relatorio como colidido.
    $r.FUNCS      = Get-Valor $d.Txt 'Funcoes detectadas'
    $nTrava       = [int](Get-Valor $d.Txt 'Trava VldDescRel rem\.' '0')
    $r.TRAVA      = if ($nTrava -gt 0) { "rem($nTrava)" } else { '-' }
    $nSc          = [int](Get-Valor $d.Txt 'StaticCall -> macro' '0')
    $r.STATICCALL = if ($nSc -gt 0) { "$nSc" } else { '-' }

    # Box-art sem folga: o engine avisa que a borda direita ficou 1 coluna maior.
    $mb = [regex]::Match($d.Txt, '(?im)^\s*Box-art realinhado\s*:?\s*(\d+)\s*ok\s*/\s*(\d+)\s*sem folga')
    if ($mb.Success -and [int]$mb.Groups[2].Value -gt 0) {
        $r.OBS = "box-art sem folga em $($mb.Groups[2].Value) linha(s)"
    }

    if ((Get-Valor $d.Txt 'Colisao 10-char' 'False') -eq 'True' -or $d.Txt -match '(?im)^WARNING.*COLISAO 10-char') {
        $r.ENGINE = 'COLISAO-10CH'
        $r.OBS    = (@($r.OBS, 'resolver manual (SKILL secao 3)') | Where-Object { $_ }) -join '; '
        if (-not $DryRun) { Move-Item -LiteralPath $trabalho -Destination "$alvo.FALHOU" -Force }
        $res += $r; continue
    }
    if ($d.Rc -ne 0) {
        $r.ENGINE = "DRYRUN-RC$($d.Rc)"; $r.OBS = 'ver 1-dryrun.txt'
        if (-not $DryRun) { Move-Item -LiteralPath $trabalho -Destination "$alvo.FALHOU" -Force }
        $res += $r; continue
    }

    if ($DryRun) { $r.ENGINE = 'dry-ok'; $res += $r; continue }

    # --- 3b. aplicar o engine ------------------------------------------------
    $e = Invoke-Filho -Script $engine -ChildArgs @('-Path', $trabalho, '-Prefix', $Prefix) `
                      -LogFile (Join-Path $LogDir "$cod.2-engine.txt")
    if ($e.Rc -ne 0) {
        # Tripwire do engine: quando falha ele NAO grava -> o arquivo no destino ainda
        # e o fonte PADRAO. Renomeia p/ .FALHOU para nao ser compilado por engano (C2021).
        $r.ENGINE = "FALHOU-RC$($e.Rc)"; $r.OBS = 'ver 2-engine.txt'
        Move-Item -LiteralPath $trabalho -Destination "$alvo.FALHOU" -Force
        $res += $r; continue
    }
    $r.ENGINE = 'ok'

    # --- 4. copiar o .ch (verbatim) -----------------------------------------
    $ch = Join-Path $hit.Directory.FullName "$cod.ch"
    if (-not (Test-Path -LiteralPath $ch)) {
        $r.CH = 'sem-ch'
    } elseif (-not $IncludeDir) {
        $r.CH = 'PENDENTE'; $r.OBS = ($r.OBS, 'passe -IncludeDir p/ copiar o .ch' -ne '' -join '; ')
    } else {
        $destCh = Join-Path $IncludeDir "$cod.ch"
        $r.CH = if (Test-Path -LiteralPath $destCh) { 'ja-tinha' } else { 'copiado' }
        [System.IO.File]::Copy($ch, $destCh, $true)
    }

    # --- 5. validar ----------------------------------------------------------
    $vArgs = @('-Path', $trabalho, '-Prefix', $Prefix)
    if ($IncludeDir) { $vArgs += @('-IncludeDir', $IncludeDir) }
    $v = Invoke-Filho -Script $valida -ChildArgs $vArgs -LogFile (Join-Path $LogDir "$cod.3-valida.txt")
    $r.VALIDADOR = switch ($v.Rc) { 0 { 'PASS' } 2 { 'FAIL' } default { "RC$($v.Rc)" } }
    if ($v.Rc -ne 0) {
        $falhas = [regex]::Matches($v.Txt, '(?m)^FAIL\s+(.+?)\s*$') | ForEach-Object { $_.Groups[1].Value }
        $r.OBS  = (@($r.OBS) + $falhas | Where-Object { $_ }) -join '; '
    }

    # --- heuristica PARAMIXB (secao 7.1) ------------------------------------
    # Relatorio cuja funcao principal declara parametros pode ser chamado por rotina
    # padrao via MV_* (ExecBlock -> PARAMIXB). Sem parametros, so ha o caminho do menu.
    # E heuristica: confirmar o contrato do ExecBlock na rotina chamadora antes do shim.
    $src = [System.IO.File]::ReadAllText($trabalho, [System.Text.Encoding]::GetEncoding(28591))
    $mu  = [regex]::Match($src, '(?im)^\s*User\s+Function\s+\w+\s*\(([^\)]*)\)')
    $r.'PARAMIXB?' = if ($mu.Success -and $mu.Groups[1].Value.Trim()) { 'CHECAR' } else { '-' }

    $res += $r
}

# --- saida -------------------------------------------------------------------
""
$res | Format-Table -AutoSize
$csv = Join-Path $LogDir 'resumo.csv'
$res | Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8

# Em dry-run o validador nao roda: o criterio de sucesso e o proprio dry-ok.
$ok        = if ($DryRun) { $res | Where-Object { $_.ENGINE -eq 'dry-ok' } }
             else         { $res | Where-Object { $_.VALIDADOR -eq 'PASS' } }
$okCount   = @($ok).Count
$ruins     = $res | Where-Object { $_.CODIGO -notin @($ok).CODIGO }
$probCount = @($ruins).Count
""
"{0}: {1} de {2}.  Detalhe por relatorio em: {3}" -f $(if($DryRun){'DRY-OK'}else{'PASS'}), $okCount, $res.Count, $LogDir
if ($probCount -gt 0) {
    "Revisar: " + (($ruins | ForEach-Object { $_.CODIGO }) -join ', ')
}
$comShim = $res | Where-Object { $_.'PARAMIXB?' -eq 'CHECAR' }
if (@($comShim).Count -gt 0) {
    "PARAMIXB (SKILL secao 7.1) - conferir se alguma rotina padrao chama via MV_*: " +
        (($comShim | ForEach-Object { $_.CODIGO }) -join ', ')
}
if (-not $DryRun) { "Proximo passo: compilar e testar no AppServer (SKILL.md secao 7) - unica prova 100%." }
if ($probCount -gt 0) { exit 2 }
