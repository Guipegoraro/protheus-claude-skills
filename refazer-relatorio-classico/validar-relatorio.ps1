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

$enc   = [System.Text.Encoding]::GetEncoding(28591)   # Latin-1: le bytes 1:1
$text  = [System.IO.File]::ReadAllText($Path, $enc)
$bytes = [System.IO.File]::ReadAllBytes($Path)
$fail  = 0
function Chk($n, $ok, $d="") {
    "{0}  {1}{2}" -f $(if($ok){"PASS"}else{"FAIL"}), $n, $(if($d){" -> $d"}else{""})
    if (-not $ok) { $script:fail++ }
}

$declRe = [regex]'(?im)^[ \t]*(User[ \t]+Function|Static[ \t]+Function|Function)[ \t]+(\w+)'
$decls = @()
foreach ($m in $declRe.Matches($text)) {
    $decls += [pscustomobject]@{ Keyword=($m.Groups[1].Value -replace '[ \t]+',' '); Name=$m.Groups[2].Value }
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

# 2) Regra dos 10 caracteres (C2021)
$trunc = @{}; $col = @()
foreach ($d in $decls) {
    $t = ($d.Name.ToUpper()).Substring(0, [Math]::Min(10, $d.Name.Length))
    if ($trunc.ContainsKey($t)) { $col += ("$($trunc[$t]) vs $($d.Name) [$t]") } else { $trunc[$t] = $d.Name }
}
Chk "Regra dos 10 caracteres (sem colisao C2021)" ($col.Count -eq 0) ($col -join '; ')

# 3) Nenhuma chamada CRUA (sem prefixo) das proprias funcoes.
#    base = nome sem o prefixo; \bBase(  so casa se NAO houver caractere de palavra antes
#    (logo 'zBase(' nao casa; 'Base->' e "Base" (string) tambem nao, pois nao tem '(' logo apos).
$bases = @($decls | ForEach-Object { if ($_.Name -like "$Prefix*") { $_.Name.Substring($Prefix.Length) } else { $_.Name } } | Select-Object -Unique)
$leftover = @()
foreach ($b in $bases) {
    if ([string]::IsNullOrEmpty($b)) { continue }
    $re = [regex]('(?i)(?<![0-9A-Za-z_])' + [regex]::Escape($b) + '[ \t]*\(')
    if ($re.IsMatch($text)) { $leftover += $b }
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

# 5) PERIGO: funcao propria (agora Static) chamada via macro/ExecBlock -> macro nao enxerga Static.
#    Lista linhas com &(/ExecBlock/RunDef E um z<base>( , exceto a linha do StaticCall wrap.
$ownAlt = ($bases | Where-Object { $_ } | ForEach-Object { [regex]::Escape($Prefix + $_) }) -join '|'
$suspect = @()
if ($ownAlt) {
    $mr = [regex]('(?im)^.*(&\(|ExecBlock|RunDef|RunBlock).*\b(' + $ownAlt + ')[ \t]*\(.*$')
    $suspect = @($mr.Matches($text) | ForEach-Object { $_.Value.Trim() } | Where-Object { $_ -notmatch '(?i)StaticCall' })
}
Chk "Nenhuma funcao propria (Static) chamada via macro/ExecBlock" ($suspect.Count -eq 0)
foreach ($s in $suspect) { "     ! $s" }

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
