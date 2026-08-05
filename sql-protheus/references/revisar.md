# Revisar SQL existente — workflow, checklists e relatorio

## Conteudo
- Workflow de review
- Checklist Embedded SQL / statement
- Checklist Workarea
- Checklist de seguranca
- Formato do relatorio

## Workflow

1. Delimitar escopo (arquivos/trechos) e banco-alvo (MSSQL, Oracle, PostgreSQL ou os tres).
2. Aplicar os checklists abaixo + a tabela de anti-padroes do SKILL.md.
3. Cross-database: qualquer funcao nao-ANSI ou paginacao nativa -> conferir [cross-database.md](cross-database.md).
4. Classificar achados: CRITICAL (injection, filtro mandatorio ausente, quebra em um dos 3 bancos) / HIGH (leak de alias/statement, full scan em tabela de movimento) / MEDIUM (padrao defasado tipo %nolock%, TCQuery legado) / LOW (estilo).
5. Relatorio no formato abaixo, ordenado por severidade.

Regras do ecossistema (herdadas do code-review categoria 9): mutacao de dicionario em fonte (`PutSX3/PutSX6/PutMV`, RecLock em SX*) = CRITICAL; bloqueio de regra de negocio sem `// Ref:` do cliente = MAJOR.

## Checklist — Embedded SQL / statement

- [ ] `RetSqlName()` para nome fisico (nunca `SA1010` hardcoded)
- [ ] `D_E_L_E_T_ = ' '` (espaco) em TODAS as tabelas, inclusive JOINs
- [ ] Filtro de filial por tabela; join de filial via `FwJoinFilial`, nunca `A._FILIAL = B._FILIAL`
- [ ] WHERE presente (minimo `1=1`)
- [ ] Valores dinamicos via bind (`SetString/SetNumeric/SetDate/SetIn`); zero concatenacao de input
- [ ] `ChangeQuery()` antes do `New()` (exceto Embedded, que aplica sozinha)
- [ ] `SetUnsafe` so com identificador interno (RetSqlName, FwJoinFilial, campos)
- [ ] Alias via `GetNextAlias()`; fechado com `DbCloseArea()` em todos os caminhos
- [ ] `Destroy()` do statement (ou cache de statement deliberado e documentado)
- [ ] Campos listados; sem `IIF()`; sem funcao especifica de um SGBD sem branch `TCGetDB()`
- [ ] `TCSqlExec`: retorno `< 0` checado com `TCSQLError()`

## Checklist — Workarea

- [ ] `DbSelectArea()` + `DbSetOrder(n)` no indice SIX correto (ordem errada = full scan)
- [ ] `DbSeek()` com prefixo de filial (`xFilial("XXX") + chave`)
- [ ] Escrita entre `RecLock()` / `MsUnlock()`
- [ ] Loop `While !Eof()` com `ALIAS->(DbSkip())` e condicao de chave (nao varrer a tabela toda)
- [ ] `GetArea()`/`RestArea()` quando a rotina nao e dona do posicionamento
- [ ] Volume grande? Entao deveria ser SQL, nao ISAM

## Checklist — seguranca

- [ ] Nenhum input de requisicao HTTP/tela/arquivo concatenado em query
- [ ] Nenhum `SetUnsafe`/`&(macro)`/`%exp:%` recebendo fragmento SQL montado com input externo
- [ ] LIKE com wildcard montado no AdvPL e bindado como um unico `?`
- [ ] Tamanho de input validado contra SX3 antes de INSERT/UPDATE
- [ ] Mensagem de erro ao cliente nao expoe estrutura de tabela

## Formato do relatorio

````
## [SEVERIDADE] [CATEGORIA]: resumo curto

**Local**: arquivo:linha (funcao)
**Problema**: o que esta errado e por que
**Risco**: injection / dado errado / quebra em <banco> / performance
**Fix**:

Antes:
```sql
-- trecho problematico
```
Depois:
```sql
-- trecho corrigido
```
````

Encerrar com: contagem por severidade + top 3 acoes prioritarias. Veredicto: PASS / PASS COM OBSERVACOES / NEEDS REVISION (qualquer CRITICAL => NEEDS REVISION).
