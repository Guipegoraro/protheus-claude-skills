# Cross-database — MSSQL / Oracle / PostgreSQL

## Conteudo
- O que e traduzido automaticamente
- O que NAO e traduzido (quebra)
- Gotchas por banco
- Ferramentas de deteccao

## Traduzido automaticamente

Pela **ChangeQuery** (todos os bancos): normalizacao de espacos; remocao de `NOLOCK`/`(NOLOCK)`; `SUBSTRING` -> funcao do banco; `||` -> concatenacao do banco; `= ''` -> `= ' '`; ORDER BY nominal -> ordinal (Informix/DB2-AS400); `FOR READ ONLY` (DB2).

Pelo **DBAccess, so em PostgreSQL**: cast `::float8` em `sum()`/`count()`; `||` -> `CONCAT(...)::bpchar` (Postgres descarta espacos a direita de bpchar na concatenacao); `::bpchar` no retorno de `LEFT/RIGHT/LOWER/UPPER/SUBSTRING/CHR/REPLACE/TRIM` (senao `upper(campo) = 'ABCDE     '` nao acha nada). Escape hatch: `SELECT /*PASSTHROUGH*/ ...` (DBAccess >= 24.1.1.1) manda a query crua, sem nenhum ajuste.

## NAO traduzido — quebra entre bancos

| Item | Problema | Solucao portavel |
| --- | --- | --- |
| `ISNULL` / `NVL` / `CONVERT` / `TO_CHAR` / funcoes de data nativas | Sem traducao | `COALESCE`, `CASE WHEN`; branch por `TCGetDB()` ("MSSQL"/"ORACLE"/"POSTGRES") quando inevitavel |
| `TOP` / `LIMIT` / `OFFSET-FETCH` (MSSQL < 2012) | Sem traducao | `ROW_NUMBER() OVER(...)` + BETWEEN (ver otimizar.md) |
| `= ''` em WHERE | Oracle: NUNCA retorna registro, silenciosamente | `= ' '` (ChangeQuery corrige quando detecta — nao dependa) |
| Joins `*=` | Nao suportado | ANSI JOIN |
| Tamanho de coluna calculada | `MIN(char10)` = 10 bytes na maioria, 255 no Postgres; `LEFT(c,5)` = 5 na maioria, 4000 no DB2 | Alias + `TCSetField`/`aSetField` em TODA coluna calculada |
| Concatenacao pesada em SQL | Alto custo (area temporaria) | Concatenar no AdvPL quando possivel |

## Gotchas por banco

- **Oracle**: collation homologada `WE8MSWIN1252`; `CURSOR_SHARING` diferente de `EXACT` nao suportado; `= ''` retorna vazio; isolation READ COMMITTED.
- **PostgreSQL**: comportamento bpchar acima; isolation READ COMMITTED; `Min(R_E_C_N_O_)` teve bug historico via ChangeQuery.
- **MSSQL**: conexao ja e READ UNCOMMITTED (por isso NOLOCK e ruido); temporarias nao sao transacionadas.

## Deteccao

- `TCGetDB()` para branch em runtime — isolar o SQL especifico numa funcao com nome que declare o banco (`MssqlXxxQry()`), nunca espalhar `If TCGetDB()` pelo fonte.
- Teste minimo de portabilidade em review: a query roda nos 3 bancos? Se usa qualquer item da tabela "NAO traduzido", precisa de justificativa ou branch.
- Campos de controle novos (`I_N_S_D_T_`, `S_T_A_M_P_`): timestamp UTC; so via query; CAST por banco para hora completa (`convert(varchar(23),...,21)` MSSQL, `to_char(...,'YYYY-MM-DD HH24:MI:SS.MS')` Postgres, `...FF` Oracle); NULL em registros anteriores a ativacao.
