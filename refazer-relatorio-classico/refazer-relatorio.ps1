param(
    [Parameter(Mandatory=$true)][string]$Path,       # arquivo z*.prw JA COPIADO (edita in-place)
    [string]$Prefix = "z",
    [switch]$DryRun
)

# ============================================================================
#  Engine da skill "refazer-relatorio-classico".
#  Transforma um fonte de relatorio classico padrao TOTVS (ja copiado para o
#  repo com nome z*.prw) numa copia customizada compilavel SEM chave:
#    - funcao principal (1a declaracao) -> User Function  z<Nome>
#    - demais funcoes                    -> Static Function z<Nome>
#    - declaracoes (mesmo sem "()")      -> prefixo z   (ancora ^KW Nome\b)
#    - chamadas/referencias              -> prefixo z   (regra \bNome( )
#    - StaticCall(A,B)                   -> &("StaticCall(A,B)")  (macro-exec)
#  NAO toca strings, aliases Nome->, #include nem comentarios (regra do "(").
#  NAO edita/renomeia o .ch (copiar o .ch e passo a parte, verbatim).
# ============================================================================

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

# 1) Detecta declaracoes de funcao (inicio de linha): User/Static Function / Function
$declRe = [regex]'(?im)^[ \t]*(User[ \t]+Function|Static[ \t]+Function|Function)[ \t]+(\w+)'
$decls = @()
foreach ($m in $declRe.Matches($text)) {
    $kw = ($m.Groups[1].Value -replace '[ \t]+',' ')
    $decls += [pscustomobject]@{ Keyword = $kw; Name = $m.Groups[2].Value }
}
if ($decls.Count -eq 0) { Write-Error "Nenhuma funcao encontrada em $Path"; exit 1 }

$main  = $decls[0].Name                                   # entry-point = primeira declaracao
$names = @($decls | ForEach-Object { $_.Name } | Select-Object -Unique)

# 2) Regra dos 10 caracteres (erro C2021) sobre os nomes ja prefixados
$trunc = @{}; $collision = $false
foreach ($n in $names) {
    $z = ($Prefix + $n).ToUpper()
    $t = $z.Substring(0, [Math]::Min(10, $z.Length))
    if ($trunc.ContainsKey($t)) { Write-Warning ("COLISAO 10-char: {0} vs {1} -> {2}" -f $trunc[$t], $z, $t); $collision = $true }
    else { $trunc[$t] = $z }
}

# 3) StaticCall -> macro-execucao &("StaticCall(...)")  (forma de 2 argumentos)
$scTotal = ([regex]'(?i)StaticCall\(').Matches($text).Count
$scRe = [regex]'(?i)StaticCall\([ \t]*\w+[ \t]*,[ \t]*\w+[ \t]*\)'
$scCount = 0
$text = $scRe.Replace($text, {
    param($m)
    $inner = ($m.Value -replace '[ \t]*,[ \t]*', ',') -replace '[ \t]+',''
    $script:scCount++
    '&("' + $inner + '")'
})
$scComplex = $scTotal - $scCount
if ($scComplex -gt 0) { Write-Warning ("{0} StaticCall( em forma complexa (>2 args ou args aninhados) - converter manualmente para macro" -f $scComplex) }

# 4a) Renomeia as DECLARACOES (inicio de linha), INDEPENDENTE de terem "(".
#     Cobre "Function Nome" sem parenteses: a regra \bNome( do 4b renomeia a CHAMADA
#     (zNome()) mas deixaria a DECLARACAO como Nome -> chamada a funcao inexistente.
#     Ancorada em ^KW e com \b apos o nome (nao pega ImpItem dentro de ImpItemR4).
foreach ($n in $names) {
    $rd = [regex]('(?im)^([ \t]*(?:User[ \t]+Function|Static[ \t]+Function|Function)[ \t]+)' + [regex]::Escape($n) + '\b')
    $text = $rd.Replace($text, '${1}' + $Prefix + $n)
}

# 4b) Renomeia CHAMADAS/REFERENCIAS: \bNome(  ->  zNome(
#     (ignora strings "Nome", aliases Nome->, #include "Nome.CH" e comentarios: nenhum tem "(" logo apos;
#      as declaracoes ja viraram zNome no 4a, entao \bNome( nao as reprefixa)
foreach ($n in $names) {
    $r = [regex]::new('(?i)\b' + [regex]::Escape($n) + '[ \t]*\(')
    $text = $r.Replace($text, ($Prefix + $n + '('))
}

# 5) Ajuste de palavra-chave: principal -> User Function ; demais publicas -> Static Function
$reMain = [regex]('(?im)^([ \t]*)Function[ \t]+' + [regex]::Escape($Prefix + $main) + '\b')
$text = $reMain.Replace($text, { param($m) $m.Groups[1].Value + 'User Function ' + $Prefix + $main })
foreach ($d in $decls) {
    if (($d.Keyword -ieq 'Function') -and ($d.Name -ne $main)) {
        $rePub = [regex]('(?im)^([ \t]*)Function[ \t]+' + [regex]::Escape($Prefix + $d.Name) + '\b')
        $text = $rePub.Replace($text, { param($m) $m.Groups[1].Value + 'Static Function ' + $Prefix + $d.Name }.GetNewClosure())
    }
}

# 6) Auto-verificacao: toda declaracao tem de ter saido prefixada. Tripwire para o
#    caso historico da declaracao sem "()" que escapava da renomeacao (ver 4a).
$postBad = @()
foreach ($m in $declRe.Matches($text)) {
    if ($m.Groups[2].Value -cnotlike "$Prefix*") { $postBad += $m.Groups[2].Value }
}
if ($postBad.Count -gt 0) {
    Write-Warning ("Declaracoes SEM prefixo apos transformacao: {0} - arquivo nao sera gravado; revisar" -f (($postBad | Select-Object -Unique) -join ', '))
}

# Relatorio
"===== $Path ====="
"Main (User Function): U_$Prefix$main"
"Funcoes detectadas  : $($names.Count)"
"Trava VldDescRel rem.: $travaCount"
"StaticCall -> macro  : $scCount"
"Colisao 10-char      : $collision"
($decls | ForEach-Object {
    $finalKw = if ($_.Name -eq $main) { 'User Function' } elseif ($_.Keyword -ieq 'Function') { 'Static Function' } else { $_.Keyword }
    "  - {0,-16} {1}" -f $finalKw, ($Prefix + $_.Name)
}) -join "`n"

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
