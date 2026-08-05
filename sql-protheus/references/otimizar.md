# Otimizar — indices, paginacao, cache, plano

## Conteudo
- Indices SIX
- Paginacao (padrao TOTVS + SQL portavel)
- Cache de query (FWQueryCache / lifetime)
- Medicao (TCSqlPlan, GetLastQuery)
- Tabelas de alto volume
- Metodologia

## Indices SIX

- WHERE na ordem dos campos do indice (esquerda -> direita), mesmo com condicoes extras fora do indice — e o que faz o otimizador usar o indice.
- ORDER BY so quando o resultado precisa vir ordenado (custa); preferir ORDER BY que case com indice existente.
- Indice novo: SEMPRE via Configurador/SIX (skill `protheus-configurador-dicionario` -> pre-producao.md); nunca ad-hoc no banco. Indices virtualizados do DBAccess existem, mas manutencao e no Configurador.
- Consultar indices disponiveis: skill `data-dictionary-lookup` (SIX da referencia) + dicionario real do cliente via `genericquery`.
- Limite: 255 colunas por query.

## Paginacao

Contrato REST TOTVS (guia API V2.0): parametros `page`/`pageSize` (semantica multiplicadora: page=2&pageSize=20 => registros 21-40), resposta `{ "hasNext": bool, "items": [...] }`. Nunca retornar tudo. Nao existe `startIndex`/`count` no padrao. Detalhes de endpoint: skill `protheus-api-poui`.

SQL portavel (MSSQL/Oracle/Postgres — ChangeQuery NAO traduz TOP/LIMIT/OFFSET):

```advpl
nStart := (nPage - 1) * nPageSize + 1
nEnd   := nPage * nPageSize + 1        // pede 1 a mais: se vier, hasNext = .T.

cQuery := "SELECT * FROM ( "
cQuery += "  SELECT ROW_NUMBER() OVER(ORDER BY SE1.E1_FILIAL, SE1.E1_NUM) AS LINHA, SE1.E1_NUM, SE1.E1_VALOR "
cQuery += "    FROM " + RetSqlName("SE1") + " SE1 "
cQuery += "   WHERE SE1.D_E_L_E_T_ = ? AND SE1.E1_FILIAL = ? "
cQuery += ") TAB WHERE LINHA BETWEEN ? AND ?"
```

`OFFSET ? ROWS FETCH NEXT ? ROWS ONLY` funciona nos 3 bancos modernos, mas quebra em MSSQL < 2012 — ROW_NUMBER e o denominador seguro. NUNCA paginar em AdvPL (`COUNT TO` + `DBSkip(n)` traz tudo do banco). COUNT correlacionado para total = full scan por request — so se o contrato exigir `total`.

`FWAdapterBaseV2` pagina internamente (via banco em alguns SGBDs, temp table nos demais — mecanismo nao documentado; nao afirmar detalhes). `hasNext` sempre; `remainingRecords` lib >= 20220502; `total` lib >= 20250519.

## Cache de query

`FWExecStatement:OpenAlias/ExecScalar` com `cLifeTime`+`cTimeout` (ambos, caractere, segundos) ativam cache na DBAPI (lib >= 20200908 + DBAccess >= 20.1.1.3 — abaixo disso falha SILENCIOSAMENTE, sem erro e sem cache). Cache so acerta com query EXATAMENTE igual; memoria proporcional ao retorno.

Usar apenas em dado quase-estatico (parametros, de-para, dominios) com lifetime curto. NUNCA em saldo/estoque/titulo/status dentro de fluxo transacional.

## Medicao — antes de otimizar

- `TCSqlPlan(cQuery)` — plano de execucao do SGBD de dentro do AdvPL (AppServer >= 20.3.1.0 + DBAccess >= 22.1.1.0).
- `GetLastQuery()` apos abrir cursor: `[2]` = query real executada (pos-ChangeQuery), `[5]` = tempo em segundos.
- Regra: medir baseline -> mudar UMA coisa -> medir de novo. EXISTS vs IN nao tem doc TOTVS — decidir pelo plano, nao por dogma.

## Tabelas de alto volume

SD1/SD2/SD3, SE1/SE2/SE5, CT2, SC5/SC6: milhoes de linhas em cliente medio. Toda query nelas: colunas indexadas no WHERE, filtro de filial, campos listados, e paginacao/limite quando o consumidor e tela ou API. JOIN dessas tabelas entre si: garantir D_E_L_E_T_ + filial nos DOIS lados e chave de join coberta por indice.

## Metodologia

1. Identificar a query lenta (log do DBAccess/DBMonitor, `GetLastQuery()[5]`, reclamacao pontual)
2. Medir plano (`TCSqlPlan`) com dados realistas
3. Aplicar UMA otimizacao (indice, reescrita, filtro, paginacao)
4. Medir de novo — ganho tem que aparecer no numero, nao na intuicao
5. Registrar antes/depois (o formato "antes X / agora Y" e o que o cliente entende)
