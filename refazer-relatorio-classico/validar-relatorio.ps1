param(
    [Parameter(Mandatory=$true)][string]$Path,        # z*.prw JA transformado pelo engine
    [string]$Prefix = "z",
    [string]$IncludeDir = ""                           # pasta \include do Protheus do ambiente (opcional; sem ela, pula a checagem de includes)
)

# ============================================================================
#  Validacao pos-engine da skill "refazer-relatorio-classico".
#  Checa mecanicamente tudo que da pra checar SEM compilar. Nao substitui o
#  teste de compilacao/execucao no AppServer, mas fecha as falhas mecanicas.
#  Saida: PASS/FAIL por item + RESULTADO final (exit 0 = ok, 2 = falhou).
# ============================================================================

. (Join-Path $PSScriptRoot 'lib-segmentos.ps1')

$enc   = [System.Text.Encoding]::GetEncoding(28591)   # Latin-1: le bytes 1:1
$text  = [System.IO.File]::ReadAllText($Path, $enc)
$bytes = [System.IO.File]::ReadAllBytes($Path)
$fail  = 0
function Chk($n, $ok, $d="") {
    "{0}  {1}{2}" -f $(if($ok){"PASS"}else{"FAIL"}), $n, $(if($d){" -> $d"}else{""})
    if (-not $ok) { $script:fail++ }
}

# Separa CODIGO x COMENTARIO: as checagens de codigo nao podem disparar por causa
# de um comentario, e a checagem de comentario nao pode olhar o codigo.
$doc     = Split-AdvplText $text
$codigo  = ($doc | ForEach-Object { ($_.Segs | Where-Object { -not $_.C } | ForEach-Object { $_.T }) -join '' }) -join "`n"

$declRe = [regex]'(?i)^[ \t]*(User[ \t]+Function|Static[ \t]+Function|Function)[ \t]+(\w+)'
$decls = @()
foreach ($ln in $doc) {
    if ($ln.Segs.Count -eq 0 -or $ln.Segs[0].C) { continue }
    $m = $declRe.Match($ln.Segs[0].T)
    if ($m.Success) { $decls += [pscustomobject]@{ Keyword=($m.Groups[1].Value -replace '[ \t]+',' '); Name=$m.Groups[2].Value } }
}
if ($decls.Count -eq 0) { Write-Error "Nenhuma funcao encontrada em $Path"; exit 1 }

"===== VALIDACAO: $Path ====="
"Funcoes declaradas: $($decls.Count)"
""

# 1) Prefixo e palavra-chave nas declaracoes
$bad = @($decls | Where-Object { $_.Name -notlike "$Prefix*" })
Chk "Todas as funcoes com prefixo '$Prefix'" ($bad.Count -eq 0) ($bad.Name -join ', ')
$u = @($decls | Where-Object { $_.Keyword -ieq 'User Function' })
Chk "Exatamente 1 User Function (entry-point)" ($u.Count -eq 1) ("achou " + $u.Count + ": " + ($u.Name -join ','))
$p = @($decls | Where-Object { $_.Keyword -ieq 'Function' })
Chk "Nenhuma 'Function' publica sobrando (fora a principal)" ($p.Count -eq 0) ($p.Name -join ', ')

# 2) Regra dos 10 caracteres (C2021) sobre o SIMBOLO gerado: User Function vira
#    U_<nome>, Static/Function ficam com o nome puro. Sao espacos distintos --
#    "Function X" e "User Function X" no mesmo fonte nao colidem.
$trunc = @{}; $col = @()
foreach ($d in $decls) {
    $sym = $(if ($d.Keyword -ieq 'User Function') { "U_" + $d.Name } else { $d.Name }).ToUpper()
    $t   = $sym.Substring(0, [Math]::Min(10, $sym.Length))
    if ($trunc.ContainsKey($t)) { $col += ("$($trunc[$t]) vs $sym [$t]") } else { $trunc[$t] = $sym }
}
Chk "Regra dos 10 caracteres (sem colisao C2021)" ($col.Count -eq 0) ($col -join '; ')

# 3) Nenhuma chamada CRUA (sem prefixo) das proprias funcoes.
#    base = nome sem o prefixo; \bBase(  so casa se NAO houver caractere de palavra antes
#    (logo 'zBase(' nao casa; 'Base->' e "Base" (string) tambem nao, pois nao tem '(' logo apos).
$bases = @($decls | ForEach-Object { if ($_.Name -like "$Prefix*") { $_.Name.Substring($Prefix.Length) } else { $_.Name } } | Select-Object -Unique)
$leftover = @()
foreach ($b in $bases) {
    if ([string]::IsNullOrEmpty($b)) { continue }
    #  Base(  ou  U_Base(  -- a 2a forma escapa do lookbehind por causa do "_" e
    #  chamaria a funcao PADRAO do RPO em vez da nossa copia.
    $re = [regex]('(?i)(?<![0-9A-Za-z_])(U_)?' + [regex]::Escape($b) + '[ \t]*\(')
    if ($re.IsMatch($codigo)) { $leftover += $b }
}
Chk "Sem chamada crua das proprias funcoes (todas com $Prefix)" ($leftover.Count -eq 0) ($leftover -join ', ')

# 4) StaticCall: todos convertidos para macro &("StaticCall(...)")
$scAll = ([regex]'(?i)StaticCall\(').Matches($text)
$scWrapped = 0
foreach ($m in $scAll) { if ($m.Index-3 -ge 0 -and $text.Substring($m.Index-3,3) -eq '&("') { $scWrapped++ } }
$scBare = $scAll.Count - $scWrapped
Chk "StaticCall convertido p/ macro &(...)" ($scBare -eq 0) ("$scBare cru(s)")

# 4b) TRAVA DE DESCONTINUACAO removida: nao pode sobrar o USO ativo de VldDescRel
#     (a chamada VldDescRel(...) ou o ExistFunc("VldDescRel")). Mencao em comentario nao conta.
$trava = ([regex]'(?i)(VldDescRel[ \t]*\(|"VldDescRel")').Matches($text).Count
Chk "Trava de descontinuacao (VldDescRel) removida" ($trava -eq 0) ("ainda ha $trava uso(s) ativo(s) - relatorio nasceria travado")

# 5) PERIGO: funcao propria (agora Static) executada por NOME em runtime -> macro e
#    ExecBlock so enxergam funcao publica/User, nunca Static.
#    So conta quando o nome esta DENTRO da string executada:
#        &("zFoo(...)")            |  ExecBlock("zFoo",...)
#    Uma chamada normal como  &(cVar):Cell(x):SetPicture(zFoo(y))  NAO e perigo:
#    zFoo ali e argumento compilado, nao faz parte da macro.
$ownAlt = ($bases | Where-Object { $_ } | ForEach-Object { [regex]::Escape($Prefix + $_) }) -join '|'
$suspect = @()
if ($ownAlt) {
    $reMacro = [regex]('(?i)&\([ \t]*"[^"]*(?<![0-9A-Za-z_])(?:' + $ownAlt + ')[ \t]*\(')
    $reExec  = [regex]('(?i)\b(?:ExecBlock|RunDef|RunBlock)[ \t]*\([ \t]*"(?:' + $ownAlt + ')"')
    $linhas  = $codigo -split "`n"
    for ($i = 0; $i -lt $linhas.Count; $i++) {
        if ($linhas[$i] -match '(?i)StaticCall') { continue }        # wrap gerado pelo engine
        if ($reMacro.IsMatch($linhas[$i]) -or $reExec.IsMatch($linhas[$i])) { $suspect += ("L" + ($i+1) + ": " + $linhas[$i].Trim()) }
    }
}
Chk "Nenhuma funcao propria (Static) executada por nome em macro/ExecBlock" ($suspect.Count -eq 0)
foreach ($s in $suspect) { "     ! $s" }

# 5b) AVISO (nao reprova): nome de funcao propria SEM prefixo sobrando em comentario.
#     Nao quebra compilacao -- e cabecalho box-art documentando funcao que nao existe mais.
$staleCom = @()
foreach ($b in $bases) {
    if ([string]::IsNullOrEmpty($b)) { continue }
    $re = [regex]('(?i)(?<![0-9A-Za-z_])(U_)?' + [regex]::Escape($b) + '(?![0-9A-Za-z_])')
    for ($i = 0; $i -lt $doc.Count; $i++) {
        foreach ($sg in $doc[$i].Segs) {
            if ($sg.C -and $re.IsMatch($sg.T)) { $staleCom += ("L" + ($i+1) + ": " + $b); break }
        }
    }
}
if ($staleCom.Count -eq 0) { "PASS  Comentarios sem nome de funcao antigo" }
else {
    "AVISO Comentarios ainda citam o nome antigo (nao reprova; so documentacao):"
    foreach ($s in ($staleCom | Select-Object -First 10)) { "     ~ $s" }
}

# 6) Fim de linha CRLF (gotcha AdvPL: LF solto -> 'Syntax Error')
$crlf = 0; $lf = 0
for ($i=0; $i -lt $bytes.Length; $i++) { if ($bytes[$i] -eq 10) { if ($i -gt 0 -and $bytes[$i-1] -eq 13) { $crlf++ } else { $lf++ } } }
Chk "Fim de linha CRLF (sem LF solto)" ($lf -eq 0) ("LF_solto=$lf; CRLF=$crlf")

# 7) Includes referenciados no fonte existem na pasta include (report-specific + padrao)
if ([string]::IsNullOrWhiteSpace($IncludeDir)) {
    "SKIP  Includes presentes na pasta include -> passe -IncludeDir `"<...>\Protheus\include`" para checar"
} else {
    $incs = @([regex]::Matches($text, '(?im)^[ \t]*#include[ \t]+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    $missing = @()
    foreach ($i in $incs) { if (-not (Test-Path (Join-Path $IncludeDir $i))) { $missing += $i } }
    Chk "Includes presentes em $IncludeDir" ($missing.Count -eq 0) ("faltam: " + ($missing -join ', '))
}

""
if ($fail -eq 0) { "RESULTADO: PASS - checagens mecanicas ok. Falta so compilar/executar no AppServer."; exit 0 }
else { "RESULTADO: FALHOU em $fail item(ns) - revisar acima antes de compilar."; exit 2 }
