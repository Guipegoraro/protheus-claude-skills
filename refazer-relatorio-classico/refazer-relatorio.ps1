param(
    [Parameter(Mandatory=$true)][string]$Path,       # arquivo z*.prw JA COPIADO (edita in-place)
    [string]$Prefix = "z",
    [switch]$DryRun,
    [switch]$SkipComments,                           # nao renomeia nomes dentro de comentarios
    [switch]$KeepEol                                 # nao normaliza LF solto para CRLF
)

# ============================================================================
#  Engine da skill "refazer-relatorio-classico".
#  Transforma um fonte de relatorio classico padrao TOTVS (ja copiado para o
#  repo com nome z*.prw) numa copia customizada compilavel SEM chave:
#    - funcao principal (1a declaracao) -> User Function  z<Nome>
#    - demais funcoes                    -> Static Function z<Nome>
#    - declaracoes (mesmo sem "()")      -> prefixo z
#    - chamadas/referencias              -> prefixo z   (regra Nome( )
#    - StaticCall(A,B)                   -> &("StaticCall(A,B)")  (macro-exec)
#    - nome nos COMENTARIOS              -> prefixo z, PRESERVANDO a largura das
#                                          linhas de box-art (borda da caixa)
#  O fonte e separado em CODIGO x COMENTARIO (lib-segmentos.ps1) e cada parte
#  recebe uma regra diferente -- sem isso o cabecalho padrao TOTVS saia meio
#  renomeado (so onde havia "(") e com a borda direita deslocada.
#  NAO edita/renomeia o .ch (copiar o .ch e passo a parte, verbatim).
# ============================================================================

. (Join-Path $PSScriptRoot 'lib-segmentos.ps1')

# Latin-1 (28591): mapeia os 256 bytes 1:1 -> preserva box-art CP850/CP1252 sem perda.
$enc  = [System.Text.Encoding]::GetEncoding(28591)
$text = [System.IO.File]::ReadAllText($Path, $enc)

# 0) Remove a TRAVA DE DESCONTINUACAO (Release 12.1.2510+). TOTVS injeta no topo da
#    funcao principal um bloco que faz o relatorio dar Return sem rodar:
#        If ExistFunc("VldDescRel")
#            If !VldDescRel()
#                Return
#            EndIf
#        EndIf
#    Sem remover, a copia z nasce travada igual. Troca por um comentario-marcador.
$travaRe = [regex]('(?im)^(?<ind>[ \t]*)(//[^\r\n]*(?:bloqueio|Release[ \t]*12\.1\.2[0-9]|descontinua)[^\r\n]*\r?\n[ \t]*)?' +
                   'If[ \t]+ExistFunc[ \t]*\([ \t]*"VldDescRel"[ \t]*\)[ \t]*\r?\n' +
                   '[ \t]*If[ \t]*![ \t]*VldDescRel[ \t]*\([ \t]*\)[ \t]*\r?\n' +
                   '[ \t]*Return[ \t]*\r?\n' +
                   '[ \t]*EndIf[ \t]*\r?\n' +
                   '[ \t]*EndIf[ \t]*\r?\n')
$travaCount = 0
$text = $travaRe.Replace($text, {
    param($m)
    $script:travaCount++
    $m.Groups['ind'].Value + '// [refazer-relatorio] trava de descontinuacao de relatorio removida (reativa no release 12.1.2510+)' + "`r`n"
})
if ($travaCount -eq 0 -and ([regex]'(?i)VldDescRel').IsMatch($text)) {
    Write-Warning "Achei 'VldDescRel' mas NAO no formato esperado do bloco - remover a trava manualmente!"
}

# 1) Segmenta CODIGO x COMENTARIO e detecta as declaracoes de funcao.
#    A deteccao le SO o 1o segmento de codigo da linha: assim uma linha de
#    cabecalho/codigo comentado nao entra como funcao do fonte.
$doc = Split-AdvplText $text

$declRe = [regex]'(?i)^[ \t]*(User[ \t]+Function|Static[ \t]+Function|Function)[ \t]+(\w+)'
$decls = @()
foreach ($ln in $doc) {
    if ($ln.Segs.Count -eq 0 -or $ln.Segs[0].C) { continue }
    $m = $declRe.Match($ln.Segs[0].T)
    if ($m.Success) {
        $decls += [pscustomobject]@{ Keyword = ($m.Groups[1].Value -replace '[ \t]+',' '); Name = $m.Groups[2].Value }
    }
}
if ($decls.Count -eq 0) { Write-Error "Nenhuma funcao encontrada em $Path"; exit 1 }

# Entry-point: se o fonte JA tem uma "User Function", ela e o entry-point (nao criar
# outra). Alguns classicos declaram um wrapper "Function XXX()" que so chama
# "U_XXX()" -- se o wrapper virasse User Function tambem, sairiam duas
# User Function com o mesmo nome (C2021 na compilacao). Sem User Function no
# fonte, vale a 1a declaracao.
$userFuncs     = @($decls | Where-Object { $_.Keyword -ieq 'User Function' })
$mainExplicito = ($userFuncs.Count -ge 1)
$main  = $(if ($mainExplicito) { $userFuncs[0].Name } else { $decls[0].Name })
$names = @($decls | ForEach-Object { $_.Name } | Select-Object -Unique)

# Palavra-chave final de uma declaracao. UMA definicao so, usada pela transformacao,
# pela checagem de 10 chars e pelo relatorio -- para os tres nao divergirem.
#   User Function / Static Function no fonte -> mantem
#   Function                                 -> Static Function, exceto se for o
#                                               entry-point e o fonte nao declarar
#                                               nenhuma User Function propria
function Get-FinalKeyword {
    param([string]$kwOrig, [string]$nome)
    if ($kwOrig -ieq 'Function') {
        if ((-not $script:mainExplicito) -and ($nome -ieq $script:main)) { return 'User Function' }
        return 'Static Function'
    }
    return $kwOrig
}
foreach ($d in $decls) {
    $d | Add-Member -NotePropertyName FinalKw -NotePropertyValue (Get-FinalKeyword $d.Keyword $d.Name) -Force
}

# 2) Regra dos 10 caracteres (erro C2021) sobre o SIMBOLO gerado, nao sobre o nome:
#    User Function gera U_<nome>, Static/Function geram <nome>. Sao espacos
#    distintos -- comparar so o nome acusaria colisao onde nao ha.
$trunc = @{}; $collision = $false
foreach ($d in $decls) {
    $sym = $(if ($d.FinalKw -ieq 'User Function') { "U_" + $Prefix + $d.Name } else { $Prefix + $d.Name }).ToUpper()
    $t   = $sym.Substring(0, [Math]::Min(10, $sym.Length))
    if ($trunc.ContainsKey($t)) { Write-Warning ("COLISAO 10-char: {0} vs {1} -> {2}" -f $trunc[$t], $sym, $t); $collision = $true }
    else { $trunc[$t] = $sym }
}

# 3) Regexes de transformacao. Alternancia unica (nome mais longo primeiro) em vez
#    de um passe por nome: evita reprefixar o que ja foi prefixado.
$nameAlt = (($names | Sort-Object { $_.Length } -Descending) | ForEach-Object { [regex]::Escape($_) }) -join '|'

#  3a) declaracao: captura indentacao, palavra-chave, separador e nome
$reDecl = [regex]('(?i)^([ \t]*)(User[ \t]+Function|Static[ \t]+Function|Function)([ \t]+)(' + $nameAlt + ')\b')
#  3b) chamada/referencia: Nome(  -- preserva o espaco original antes do "(" e o caixa-alta/baixa do fonte
$reCall = [regex]('(?i)(?<![0-9A-Za-z_])(' + $nameAlt + ')([ \t]*)\(')
#  3b2) chamada da propria User Function pelo simbolo U_Nome( -- o "_" bloqueia o
#       lookbehind de 3b, entao sem isto o wrapper continuaria chamando a funcao
#       PADRAO do RPO em vez da nossa copia
$reUCall = [regex]('(?i)(?<![0-9A-Za-z_])(U_)(' + $nameAlt + ')([ \t]*)\(')
#  3c) dentro de comentario: nome solto, sem exigir "(" -- e o que faltava
$reCom  = [regex]('(?i)(?<![0-9A-Za-z_])(U_)?(' + $nameAlt + ')(?![0-9A-Za-z_])')
#  3d) StaticCall de 2 argumentos -> macro-execucao
$reSC   = [regex]'(?i)StaticCall\([ \t]*\w+[ \t]*,[ \t]*\w+[ \t]*\)'

$scTotal   = ([regex]'(?i)StaticCall\(').Matches($text).Count
$scCount   = 0
$comHits   = 0     # nomes renomeados dentro de comentario
$comLines  = 0     # linhas de comentario tocadas
$boxKept   = 0     # linhas de box-art que voltaram a largura original
$boxBroken = @()   # linhas de box-art sem folga para reabsorver (avisa)

function Convert-CodeSegment {
    param([string]$s, [bool]$isFirst)

    # StaticCall -> &("StaticCall(...)")
    $s = $script:reSC.Replace($s, {
        param($m)
        $script:scCount++
        '&("' + ((($m.Value -replace '[ \t]*,[ \t]*', ',') -replace '[ \t]+','')) + '")'
    })

    # Declaracao: prefixa o nome E ja resolve a palavra-chave final (ver Get-FinalKeyword)
    if ($isFirst) {
        $s = $script:reDecl.Replace($s, {
            param($m)
            $nm = $m.Groups[4].Value
            $m.Groups[1].Value + (Get-FinalKeyword $m.Groups[2].Value $nm) + $m.Groups[3].Value + $script:Prefix + $nm
        }, 1)
    }

    # Chamada da propria User Function pelo simbolo: U_Nome( -> U_zNome(
    $s = $script:reUCall.Replace($s, {
        param($m)
        $m.Groups[1].Value + $script:Prefix + $m.Groups[2].Value + $m.Groups[3].Value + '('
    })

    # Chamadas/referencias: Nome( -> zNome(  (mantem espacamento e caixa originais)
    $s = $script:reCall.Replace($s, {
        param($m)
        $script:Prefix + $m.Groups[1].Value + $m.Groups[2].Value + '('
    })
    return $s
}

function Convert-CommentSegment {
    param([string]$s)
    return $script:reCom.Replace($s, {
        param($m)
        $script:comHits++
        $m.Groups[1].Value + $script:Prefix + $m.Groups[2].Value   # preserva "U_" e a caixa usada no comentario
    })
}

# 4) Passe unico de transformacao, linha a linha
$sb = New-Object System.Text.StringBuilder
$lineNo = 0
$postBad = @()      # tripwire: declaracao que saiu do passe SEM o prefixo
foreach ($ln in $doc) {
    $lineNo++
    $novo = ''
    $hitsAntes = $comHits
    for ($k = 0; $k -lt $ln.Segs.Count; $k++) {
        $sg = $ln.Segs[$k]
        if ($sg.C) {
            $novo += $(if ($SkipComments) { $sg.T } else { Convert-CommentSegment $sg.T })
        } else {
            $out = Convert-CodeSegment $sg.T ($k -eq 0)
            if ($k -eq 0 -and $declRe.IsMatch($sg.T)) {
                $mp = $declRe.Match($out)
                if (-not $mp.Success -or $mp.Groups[2].Value -cnotlike "$Prefix*") { $postBad += $declRe.Match($sg.T).Groups[2].Value }
            }
            $novo += $out
        }
    }
    if ($comHits -gt $hitsAntes) { $comLines++ }

    # Largura: so em linha 100% comentario que e desenho de caixa. Reabsorve os
    # caracteres inseridos comendo espacos da folga, para a borda direita nao andar.
    if ($ln.AllCom -and $ln.Box -and $novo.Length -gt $ln.Content.Length) {
        $ajust = Repair-LineWidth $ln.Content $novo
        if ($ajust.Length -eq $ln.Content.Length) { $boxKept++ } else { $boxBroken += $lineNo }
        $novo = $ajust
    }

    [void]$sb.Append($novo).Append($ln.Eol)
}
$text = $sb.ToString()

# 4b) LF solto -> CRLF. Boa parte dos fontes baixados do portal vem com quebra LF,
#     e o compilador AdvPL da "Syntax Error" nesses casos (ver [[advpl-lf-crlf-syntax-error]]).
#     Idempotente: arquivo ja CRLF nao muda. -KeepEol desliga.
$lfSolto = ([regex]"(?<!`r)`n").Matches($text).Count
if ($lfSolto -gt 0 -and -not $KeepEol) { $text = ($text -replace "`r`n", "`n") -replace "`n", "`r`n" }

$scComplex = $scTotal - $scCount
if ($scComplex -gt 0) { Write-Warning ("{0} StaticCall( em forma complexa (>2 args ou args aninhados) - converter manualmente para macro" -f $scComplex) }
if ($boxBroken.Count -gt 0) {
    Write-Warning ("Box-art sem folga para reabsorver o prefixo (borda 1 coluna a mais) nas linhas: {0}" -f ($boxBroken -join ', '))
}

# 5) Auto-verificacao (acumulada no passe 4): toda declaracao tem de ter saido prefixada.
if ($postBad.Count -gt 0) {
    Write-Warning ("Declaracoes SEM prefixo apos transformacao: {0} - arquivo nao sera gravado; revisar" -f (($postBad | Select-Object -Unique) -join ', '))
}

# Relatorio
"===== $Path ====="
"Main (User Function): U_$Prefix$main"
"Funcoes detectadas   : $($names.Count)"
"Trava VldDescRel rem.: $travaCount"
"StaticCall -> macro  : $scCount"
"Nomes em comentario  : $comHits em $comLines linha(s)$(if($SkipComments){' (PULADO: -SkipComments)'})"
"Box-art realinhado   : $boxKept ok / $($boxBroken.Count) sem folga"
"LF solto -> CRLF     : $lfSolto$(if($lfSolto -gt 0 -and $KeepEol){' (PULADO: -KeepEol; validacao vai reprovar)'})"
"Colisao 10-char      : $collision"
($decls | ForEach-Object { "  - {0,-16} {1}" -f $_.FinalKw, ($Prefix + $_.Name) }) -join "`n"

$temFalha = $collision -or ($postBad.Count -gt 0)

if ($DryRun) {
    "`n[DRYRUN] nenhuma alteracao gravada."
} elseif ($temFalha) {
    "`n[ABORTADO] falha detectada (colisao 10-char ou declaracao sem prefixo) - arquivo NAO gravado."
} else {
    [System.IO.File]::WriteAllText($Path, $text, $enc)
    "`n[GRAVADO] ok."
}
if ($temFalha) { exit 2 }
