---
name: sql-protheus
description: "Builds, reviews, and tunes SQL in AdvPL/TLPP for TOTVS Protheus — FWExecStatement/FWPreparedStatement, Embedded SQL, mandatory D_E_L_E_T_/filial filters, SIX indexes, TOTVS pagination, cross-database MSSQL/Oracle/PostgreSQL. Use when writing, reviewing, or optimizing Protheus queries, or when the user says 'query', 'SQL', 'FWExecStatement', 'TCQuery', 'slow query', 'index', 'execution plan'."
---

# SQL Protheus

Skill unica para SQL em AdvPL/TLPP: construir, revisar e otimizar. Baseada na documentacao TDN oficial e no codigo-padrao TOTVS 12.1.2310+ (pesquisa 08/2026); substitui as antigas query-builder, sql-code-review e sql-optimization.

## Branches — carregue a reference do que for fazer

| Tarefa | Reference |
| --- | --- |
| CONSTRUIR query nova (SELECT, DML, bulk, temporaria, base externa) | [references/construir.md](references/construir.md) |
| REVISAR SQL existente (checklists, formato de relatorio, anti-padroes) | [references/revisar.md](references/revisar.md) |
| OTIMIZAR performance (indices, paginacao, cache, plano de execucao) | [references/otimizar.md](references/otimizar.md) |
| Compatibilidade CROSS-DATABASE (MSSQL / Oracle / PostgreSQL) | [references/cross-database.md](references/cross-database.md) |

O que segue abaixo vale para TODOS os branches.

## Filtros mandatorios

Toda query sobre tabela Protheus inclui, para CADA tabela (inclusive as do JOIN):

| Filtro | Forma correta | Nunca |
| --- | --- | --- |
| Soft-delete | `D_E_L_E_T_ = ' '` (um espaco; mais rapido que `<> '*'`) | `= ''` (zero registros em Oracle, silenciosamente) ou `<> '*'` |
| Filial | `XX_FILIAL = ?` com bind de `xFilial("XXX")` | hardcode de filial; comparar `_FILIAL` de uma tabela com `_FILIAL` de outra |
| Nome fisico | `RetSqlName("XXX")` | hardcode (`SA1010`) |
| WHERE | sempre presente, nem que seja `1=1` | query sem WHERE + GROUP BY = erro quando o filtro de acesso por empresa/filial e injetado |

Join entre tabelas com compartilhamento diferente: `FwJoinFilial(cAlias1, cAlias2)` — nunca `A._FILIAL = B._FILIAL` a mao.

## Decisao rapida — qual API usar

| Cenario | Use |
| --- | --- |
| Valor variavel, WHERE condicional, input externo | `FWExecStatement` + bind (default para codigo novo) |
| Query totalmente estatica e literal | Embedded SQL (`BeginSql` com `%table:%`, `%xfilial:%`, `%notDel%`, `%exp:%`) |
| Um valor escalar | `oStmt:ExecScalar('COL')` ou `MPSysExecScalar` |
| Resultado pequeno sem workarea (APIs) | `TCSqlToArr` |
| DML/DDL | `TCSQLExec` — checar retorno `< 0` + `TCSQLError()`; nao atualiza campos de controle do DBAccess |
| Carga em massa | `FWBulk` (com `CanBulk()` + fallback RecLock) |
| Tabela temporaria | `FWTemporaryTable` (`SharedTable` se cruzar threads); nunca alias fixo `TRB` |
| Banco EXTERNO | `FWDBAccess` + `FWPreparedStatement:setConnection()`; `Finish()` obrigatorio |
| Lookup de 1 registro por chave de indice | Workarea (`DbSelectArea`/`DbSetOrder`/`DbSeek`). Validacoes/gatilhos SX7 executam so via ExecAuto/MVC — nem RecLock nem SQL os disparam; gravacao que precisa deles vai por `MsExecAuto` |
| Varredura sequencial grande | SQL, nao ISAM (dbSkip em massa e a forma mais lenta de acesso) |

`?` no conteudo da query ou dos valores => nao use Embedded SQL (o `?` e reservado do pre-processador); use FWExecStatement.

## Template canonico de SELECT (12.1.2310+)

```advpl
Local cQuery as character
Local cAlias as character
Local oStmt  as object

cQuery := "SELECT SE1.E1_NUM, SE1.E1_VALOR "
cQuery += "  FROM " + RetSqlName("SE1") + " SE1 "
cQuery += " WHERE SE1.E1_FILIAL = ? "
cQuery += "   AND SE1.E1_CLIENTE = ? "
cQuery += "   AND SE1.D_E_L_E_T_ = ? "
cQuery += " ORDER BY SE1.E1_NUM "

oStmt := FwExecStatement():New( ChangeQuery(cQuery) )   // ChangeQuery ANTES do New — obrigatoria salvo casos especiais
oStmt:SetString(1, xFilial("SE1"))
oStmt:SetString(2, cCliente)
oStmt:SetString(3, " ")                                  // espaco, nunca ''
cAlias := oStmt:OpenAlias()                              // bind real no banco (reuso de plano)

While !(cAlias)->(Eof())
    // ...
    (cAlias)->(DbSkip())
EndDo

(cAlias)->(DbCloseArea())
oStmt:Destroy()
FwFreeObj(oStmt)
```

Regras do template: parametros de bind comecam em 1; `SetString` sem aspas simples no valor; `GetNextAlias()` quando precisar nomear alias; fechar alias e destruir statement em todos os caminhos (incluindo erro). `FWPreparedStatement:getFixQuery()` substitui valores no lado da aplicacao — protege contra injection mas nao reusa plano; `FWExecStatement:OpenAlias/ExecScalar` fazem bind no SGBD.

## Seguranca — injection

- Todo valor de origem externa (query param de REST, tela, arquivo) entra por bind (`SetString/SetNumeric/SetDate/SetIn`).
- `SetUnsafe` SOMENTE para identificadores construidos internamente (`RetSqlName`, `FwJoinFilial`, lista de campos) — nunca para valor de requisicao.
- Embedded SQL: `%exp:var%` e a forma segura (escapa o valor); montar fragmento SQL fora e injeta-lo via `%exp:%` anula o escape.
- Macro-execucao `&(cVar)` e concatenacao de input em `TCSQLExec` sao vetores classicos — proibidos.
- LIKE: montar `"%" + cBusca + "%"` no AdvPL e bindar a string inteira como um unico `?`.

## Anti-padroes (flaggear em qualquer branch)

| Anti-padrao | Por que | Fix |
| --- | --- | --- |
| `%nolock%` / `WITH (NOLOCK)` | Ruido: ChangeQuery REMOVE NOLOCK; conexao MSSQL ja e READ UNCOMMITTED | Remover |
| `D_E_L_E_T_ = ''` ou `<> '*'` | `''` = zero registros em Oracle; `<>` e mais lento | `= ' '` |
| Alias fixo (`TRB`, `QRY`) | Recursao = alias duplicado | `GetNextAlias()` |
| `SELECT *` | Dezenas de campos de sistema; limite de 255 colunas por query | Listar campos |
| Query sem WHERE | Filtro de acesso injetado + GROUP BY = erro de execucao | WHERE sempre (minimo `1=1`) |
| Funcao especifica de um SGBD (`ISNULL`, `NVL`, `CONVERT`, `TO_CHAR`) | Nao ha traducao automatica | `COALESCE`, `CASE WHEN` (ANSI) ou branch por `TCGetDB()` |
| `TOP` / `LIMIT` / `OFFSET` esperando traducao | ChangeQuery NAO traduz paginacao | `ROW_NUMBER() OVER(...)` — denominador comum (ver otimizar.md) |
| `MPSysOpenQuery`/query dentro de loop | Comentario oficial: "nao e nem um pouco aconselhavel" | Uma query que resolva o conjunto |
| ISAM (`dbSeek`+`dbSkip`) para varrer conjunto grande | Caso real TDN: 1 dbSkip de 20 min | SQL |
| `TCRefresh` rotineiro | Prejudica performance (removido ate da FWBulk) | So apos DDL via TCSQLExec |
| `IIF()` em SQL | Nao portavel | `CASE WHEN` |
| `GetMV`/`ExistBlock` dentro de loop | Custo por iteracao | Cachear em variavel antes |
| Procedure criada em fonte | Proibido | SPManager |
| Joins `*=` | Nao suportado | ANSI JOIN |
| `SE5` acessada direto | Deprecated | Familia `FKx` + ExecAuto |
| Query em SX2/SX3/SIX via DbSelectArea | Metadado tem API propria | `RetSqlName`, `FWSX3Util`, APIs padrao |

## Checklist minimo (toda entrega de SQL)

- [ ] `D_E_L_E_T_ = ' '` e filtro de filial em TODAS as tabelas (JOINs inclusive)
- [ ] `RetSqlName()` para nome fisico; `GetNextAlias()` para alias
- [ ] Valores dinamicos via bind; `ChangeQuery()` antes do `New()`
- [ ] Alias fechado + `Destroy()` em todos os caminhos
- [ ] Campos listados (sem `*`); WHERE presente; ordem do WHERE seguindo o indice SIX
- [ ] SQL ANSI ou tratado para os 3 bancos (ver cross-database.md)

## Ecossistema

- Dicionario real do cliente (campos custom, tamanhos): consulte via skill `genericquery` — a base MCP e referencia TOTVS, nao o cliente.
- Query nova que exige indice novo: registrar em `pre-producao.md` via skill `protheus-configurador-dicionario` (indice via Configurador, nunca ad-hoc em producao).
- Paginacao de API REST: contrato TOTVS `page`/`pageSize` + `{hasNext, items}` — fonte unica na skill `protheus-api-poui`.

<!-- Fusao das skills query-builder / sql-code-review / sql-optimization (MIT, Melkz Siqueira - Engenharia Protheus) reescrita a partir de pesquisa TDN + codigo-padrao TOTVS em 08/2026. -->
