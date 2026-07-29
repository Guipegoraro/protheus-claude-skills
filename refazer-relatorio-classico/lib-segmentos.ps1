# ============================================================================
#  Lib compartilhada da skill "refazer-relatorio-classico".
#  Separa um fonte AdvPL em segmentos de CODIGO x COMENTARIO, linha a linha.
#  Usada pelo engine (para renomear codigo e comentario com regras diferentes)
#  e pelo validador (para checar nome antigo sobrando em comentario).
#
#  Reconhece: // ate fim de linha | /* ... */ (inclui /*/ Protheus.doc)
#             * na coluna 1 (linha inteira, sintaxe xBase)
#  Strings ("..." e '...') sao tratadas como CODIGO, e o scanner nao confunde
#  um // dentro de string (ex.: "http://...") com inicio de comentario.
# ============================================================================

# Quebra UMA linha (sem EOL) em segmentos. $inBlock e [ref] ao estado de
# bloco /* */ aberto, carregado de uma linha para a proxima.
function Split-AdvplLine {
    param([string]$s, [ref]$inBlock)

    $segs = New-Object System.Collections.ArrayList

    # Linha inteira comentada com '*' na coluna 1 (so vale fora de bloco)
    if (-not $inBlock.Value -and $s -match '^[ \t]*\*') {
        [void]$segs.Add([pscustomobject]@{ T = $s; C = $true })
        return ,$segs.ToArray()
    }

    # Atalho: sem delimitador nenhum e fora de bloco -> linha e 100% codigo
    if (-not $inBlock.Value -and $s.IndexOf('/') -lt 0 -and $s.IndexOf('"') -lt 0 -and $s.IndexOf("'") -lt 0) {
        if ($s.Length -gt 0) { [void]$segs.Add([pscustomobject]@{ T = $s; C = $false }) }
        return ,$segs.ToArray()
    }

    $sb       = New-Object System.Text.StringBuilder
    $curIsCom = $inBlock.Value
    $i = 0; $n = $s.Length

    while ($i -lt $n) {
        $c = $s[$i]

        if ($inBlock.Value) {
            if ($c -eq '*' -and ($i + 1) -lt $n -and $s[$i + 1] -eq '/') {
                [void]$sb.Append('*/'); $i += 2
                [void]$segs.Add([pscustomobject]@{ T = $sb.ToString(); C = $true })
                [void]$sb.Clear(); $inBlock.Value = $false; $curIsCom = $false
                continue
            }
            [void]$sb.Append($c); $i++
            continue
        }

        # --- fora de bloco ---
        if ($c -eq '"' -or $c -eq "'") {          # string: consome inteira como codigo
            $q = $c; [void]$sb.Append($c); $i++
            while ($i -lt $n -and $s[$i] -ne $q) { [void]$sb.Append($s[$i]); $i++ }
            if ($i -lt $n) { [void]$sb.Append($s[$i]); $i++ }
            continue
        }
        if ($c -eq '/' -and ($i + 1) -lt $n -and $s[$i + 1] -eq '/') {   # // ate fim de linha
            if ($sb.Length -gt 0) { [void]$segs.Add([pscustomobject]@{ T = $sb.ToString(); C = $false }); [void]$sb.Clear() }
            [void]$segs.Add([pscustomobject]@{ T = $s.Substring($i); C = $true })
            return ,$segs.ToArray()
        }
        if ($c -eq '/' -and ($i + 1) -lt $n -and $s[$i + 1] -eq '*') {   # abre bloco
            if ($sb.Length -gt 0) { [void]$segs.Add([pscustomobject]@{ T = $sb.ToString(); C = $false }); [void]$sb.Clear() }
            [void]$sb.Append('/*'); $i += 2
            $inBlock.Value = $true; $curIsCom = $true
            continue
        }
        [void]$sb.Append($c); $i++
    }

    if ($sb.Length -gt 0) { [void]$segs.Add([pscustomobject]@{ T = $sb.ToString(); C = $curIsCom }) }
    return ,$segs.ToArray()
}

# Quebra o TEXTO inteiro. Devolve um objeto por linha:
#   Content = linha sem EOL | Eol = "`r`n" / "`n" / "" | Segs = segmentos
#   AllCom  = a linha inteira e comentario | Box = a linha e desenho de caixa
function Split-AdvplText {
    param([string]$text)

    $inBlock = $false
    $res = New-Object System.Collections.ArrayList

    foreach ($raw in [regex]::Split($text, '(?<=\n)')) {
        if ($raw.Length -eq 0) { continue }                 # sobra do split quando o texto termina com \n

        if     ($raw.EndsWith("`r`n")) { $eol = "`r`n"; $content = $raw.Substring(0, $raw.Length - 2) }
        elseif ($raw.EndsWith("`n"))   { $eol = "`n";   $content = $raw.Substring(0, $raw.Length - 1) }
        else                           { $eol = '';     $content = $raw }

        $segs = Split-AdvplLine $content ([ref]$inBlock)
        $allCom = ($segs.Count -gt 0)
        foreach ($sg in $segs) { if (-not $sg.C) { $allCom = $false; break } }

        [void]$res.Add([pscustomobject]@{
            Content = $content
            Eol     = $eol
            Segs    = $segs
            AllCom  = $allCom
            Box     = (Test-BoxArtLine $content)
        })
    }
    return ,$res.ToArray()
}

# Linha e "desenho de caixa"? (cabecalho padrao TOTVS em box-art CP850, ou tabela
# ASCII delimitada por | / +). Nessas linhas a LARGURA importa: a borda direita
# tem de continuar na mesma coluna das linhas vizinhas.
#
# O fonte e lido byte-a-byte (Latin-1), entao o box-art do CP850 chega como
# codepoints >= 0x80 -- NAO como box-drawing Unicode. Por isso o teste e
# estrutural (mesma borda no inicio e no fim) e nao por tabela de caracteres:
# assim funciona em CP850, CP1252 ou qualquer 8-bit.
function Test-BoxArtLine {
    param([string]$s)
    $t = $s.Trim()
    if ($t.Length -lt 20) { return $false }
    $a = $t[0]; $b = $t[$t.Length - 1]
    if ($a -cne $b) { return $false }                    # borda esq. == borda dir.
    if ([int][char]$a -ge 0x80) { return $true }         # box-art 8-bit (CP850)
    if ($a -eq '|' -or $a -eq '+') { return $true }      # tabela ASCII
    return $false
}

# Reabsorve $delta caracteres inseridos removendo ESPACOS (nunca TAB) de uma
# corrida de 2+ espacos, preferindo a primeira APOS o ponto de insercao (mesma
# celula da caixa); se nao houver, qualquer corrida da linha. Devolve a linha
# ajustada -- o chamador compara o comprimento para saber se conseguiu.
function Repair-LineWidth {
    param([string]$old, [string]$new)

    $delta = $new.Length - $old.Length
    if ($delta -le 0) { return $new }

    $p = 0; $lim = [Math]::Min($old.Length, $new.Length)
    while ($p -lt $lim -and $old[$p] -eq $new[$p]) { $p++ }

    # Preferencia 1: corrida de 2+ espacos (folga de celula) -- nunca junta palavra.
    # Preferencia 2: espaco unico COLADO numa borda (|, +, ou byte >= 0x80 do box-art)
    #                -- cabecalhos que usam TAB nao tem corrida de 2 espacos, mas tem
    #                   um espaco colado na borda. Tambem nao junta palavra.
    $reFolga = @('  +', '(?<=[\x80-\xFF|+])[ ]|[ ](?=[\x80-\xFF|+])')

    while ($delta -gt 0) {
        $idx = -1
        foreach ($pat in $reFolga) {
            if ($p -lt $new.Length) {
                $m = [regex]::Match($new.Substring($p), $pat)
                if ($m.Success) { $idx = $p + $m.Index; break }
            }
            $m2 = [regex]::Match($new, $pat)
            if ($m2.Success) { $idx = $m2.Index; break }
        }
        if ($idx -lt 0) { break }                        # sem folga: desiste (chamador avisa)
        $new = $new.Remove($idx, 1)
        $delta--
    }
    return $new
}
