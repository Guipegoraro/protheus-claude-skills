---
name: claudesql-setup
description: Use when user wants to set up ClaudeSQL REST API on a Protheus environment for running read-only SQL queries via Claude. Trigger words - "claudesql", "setup claudesql", "configurar claudesql", "instalar api sql", "query api protheus", "consulta sql rest". Also use when the user asks Claude to query the Protheus database directly and ClaudeSQL is not yet configured.
---

# ClaudeSQL Setup - REST API de consulta SQL read-only para Protheus

Voce e um assistente que configura a API REST ClaudeSQL no ambiente Protheus do usuario. Esta API permite que o Claude execute consultas SELECT read-only no banco do Protheus para auxiliar no desenvolvimento.

## REGRA CRITICA DE SEGURANCA

**NUNCA salve usuario, senha ou credenciais em nenhum arquivo permanente** — nem em CLAUDE.md, nem em memoria, nem em variaveis de ambiente, nem em arquivos de configuracao. Credenciais devem ser usadas APENAS em chamadas curl durante a sessao corrente e descartadas apos o uso.

## Fluxo obrigatorio

### Passo 1: Explicar o que sera feito

Explique brevemente ao usuario:

> **ClaudeSQL** e uma API REST TLPP que permite ao Claude executar consultas SQL read-only diretamente no banco do Protheus. Isso agiliza o desenvolvimento porque o Claude pode consultar tabelas, verificar dados e entender a estrutura do banco em tempo real.
>
> **Seguranca:** A API tem 7 camadas de validacao que bloqueiam qualquer operacao de escrita (INSERT, UPDATE, DELETE, DROP, etc.), acesso a tabelas de sistema, e tentativas de SQL injection. Funciona com SQL Server, Oracle e PostgreSQL.
>
> Vou criar um arquivo `ClaudeSQL.tlpp` no seu projeto e voce compila no RPO.

### Passo 2: Coletar informacoes (uma pergunta por vez)

**2a)** Use AskUserQuestion para perguntar onde salvar:

> Em qual pasta devo salvar o arquivo `ClaudeSQL.tlpp`?
>
> Exemplos:
> - Pasta do projeto atual (ex: `SELBETTIGIT/helpers/`)
> - Pasta separada (ex: `helpers-claude-protheus/`)
> - Outro caminho que preferir

**2b)** Use AskUserQuestion para pedir a URL do REST server:

> Qual a URL base do REST server do Protheus?
>
> Exemplos:
> - `http://localhost:8401` (ambiente local)
> - `http://192.168.1.100:8401` (servidor na rede)
> - `https://protheus.empresa.com:8401` (servidor remoto)
>
> Preciso do protocolo (http/https), host e porta.

**2c)** Use AskUserQuestion para pedir credenciais:

> Qual usuario e senha do Protheus para autenticacao Basic Auth?
>
> **IMPORTANTE:** Essas credenciais serao usadas APENAS para testar a API agora. Eu NAO vou salvar usuario/senha em nenhum arquivo, memoria ou configuracao. Serao usadas somente nas chamadas curl desta sessao.

### Passo 3: Criar o arquivo

Crie o arquivo `ClaudeSQL.tlpp` na pasta indicada pelo usuario com o conteudo completo da secao "Fonte completo" abaixo.

### Passo 4: Perguntar sobre compilacao

Use AskUserQuestion para perguntar:

> O arquivo foi criado em `{caminho}`. Como deseja compilar?
>
> 1. **Eu compilo manualmente** — Abra o arquivo no VS Code e compile pelo TDS (Ctrl+F9 ou botao de compilar)
> 2. **Claude compila** — Vou tentar compilar via extensao TDS do VS Code (precisa estar conectado ao AppServer)
>
> Qual opcao?

Se o usuario escolher opcao 2, tente compilar via CLI do TDS se disponivel. Se nao funcionar, instrua a compilacao manual.

### Passo 5: Configuracao do REST server

Apos compilacao, informe ao usuario:

> Para a API funcionar, o REST server do Protheus precisa estar configurado no `appserver.ini`. Verifique se existe a secao:
>
> ```ini
> [HTTPREST]
> Port=8401
> URIs=HTTPURI
> Security=1
>
> [HTTPURI]
> URL=/rest
> PrepareIn=99,01
> Instances=1,3
> ```
>
> - `Security=1` ativa Basic Auth (obrigatorio para seguranca)
> - `PrepareIn=99,01` define empresa/filial padrao (ajuste conforme seu ambiente)
> - Reinicie o AppServer apos alterar o appserver.ini

### Passo 6: Testar

Usando a URL e credenciais fornecidas pelo usuario (NAO hardcoded), rode os testes:

```bash
# Health check
curl -s -u "{usuario}:{senha}" {url_base}/rest/claude/health

# Query de teste
curl -s -X POST -u "{usuario}:{senha}" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT TOP 5 X2_CHAVE, X2_NOME FROM SX2990","limit":5}' \
  {url_base}/rest/claude/query

# Teste de seguranca (deve ser bloqueado)
curl -s -X POST -u "{usuario}:{senha}" -H "Content-Type: application/json" \
  -d '{"sql":"DELETE FROM SA1990"}' \
  {url_base}/rest/claude/query
```

Substitua `{usuario}`, `{senha}` e `{url_base}` pelos valores fornecidos pelo usuario no passo 2.

### Passo 7: Informar uso

> **Pronto!** A API ClaudeSQL esta configurada. Nas proximas sessoes, quando quiser que eu consulte o banco, basta me informar a URL e credenciais novamente (eu nao guardo entre sessoes).
>
> Exemplos de uso:
> - *"Quais tabelas customizadas (Z*) existem no ambiente?"*
> - *"Me mostra os 10 primeiros clientes da SA1"*
> - *"Qual a estrutura da tabela SC5?"*
>
> O Claude usara `POST /rest/claude/query` para responder.

---

## Fonte completo: ClaudeSQL.tlpp

```tlpp
#Include "TOTVS.ch"
#Include "tlpp-core.th"
#Include "tlpp-rest.th"
#Include "topconn.ch"

//-------------------------------------------------------------------
// ClaudeSQL - REST API de consulta SQL read-only para Protheus
//
// Permite que o Claude AI execute consultas SELECT no banco do
// Protheus para auxiliar no desenvolvimento. APENAS LEITURA.
//
// Endpoints:
//   GET  /claude/health  - Health check
//   POST /claude/query   - Executar consulta SQL read-only
//
// Auth: Basic Auth (usuario/senha Protheus)
//
// Seguranca (7 gates de validacao):
//   1. Query nao pode ser vazia nem exceder 8000 chars
//   2. Bloqueio de ; (multi-statement)
//   3. Bloqueio de comentarios SQL (-- e /* */)
//   4. String literals removidas antes da analise de keywords
//   5. Query deve iniciar com SELECT ou WITH
//   6. Keywords de escrita/DDL/system bloqueadas (45+ keywords)
//   7. Acesso a tabelas/schemas de sistema bloqueado (SQL Server/PG/Oracle)
//
// Notas tecnicas:
//   - ChangeQuery NAO e homologada para CTEs (WITH). Para CTEs,
//     ChangeQuery e chamada mas pode falhar em bancos nao-SQL Server.
//   - TCSetField e usado dinamicamente apos MpSysOpenQuery para
//     converter campos N/D/L que voltariam como char sem aSetField.
//   - JsonObject:ToJson() com arrays de arrays (rows) e o formato
//     padrao. Se houver problema de serializacao, verificar versao
//     do AppServer (requer 20.3.1+).
//
// @author  Guilherme Pegoraro / Claude
// @since   10/04/2026
// @version 1.1
//-------------------------------------------------------------------

#Define CLAUDESQL_VERSION   "1.1"
#Define CLAUDESQL_MAX_ROWS  1000
#Define CLAUDESQL_MAX_SQL   8000


/*/{Protheus.doc} ClaudeSQLHealth
Health check - verifica se a API esta ativa e retorna info do ambiente
@type User Function
@author Guilherme Pegoraro / Claude
@since 10/04/2026
@version 1.0
/*/
@Get(endpoint="/claude/health", description="ClaudeSQL health check")
User Function ClaudeSQLHealth() as logical
    Local oResp := JsonObject():New()

    oResp['ok']          := .T.
    oResp['version']     := CLAUDESQL_VERSION
    oResp['environment'] := GetEnvServer()
    oResp['company']     := cEmpAnt
    oResp['branch']      := cFilAnt
    oResp['database']    := TCGetDB()

    oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
    oRest:setResponse(oResp:ToJson())
    oRest:setStatusCode(200)

    FreeObj(oResp)
Return .T.


/*/{Protheus.doc} ClaudeSQLQuery
Executa consulta SQL read-only e retorna JSON otimizado para LLM.

Request body (JSON):
  sql   - (string, obrigatorio) Query SQL (apenas SELECT/WITH)
  limit - (number, opcional) Max linhas retornadas (default/max: 1000)

Response (JSON):
  ok        - (bool) Sucesso
  schema    - (array) Colunas [{name, type, size}]
  rows      - (array) Dados em array de arrays [[val, val, ...]]
  rowCount  - (number) Linhas retornadas
  truncated - (bool) Se havia mais linhas alem do limite
  ms        - (number) Tempo de execucao em ms
  error     - (string) Mensagem de erro quando ok=false

@type User Function
@author Guilherme Pegoraro / Claude
@since 10/04/2026
@version 1.1
/*/
@Post(endpoint="/claude/query", description="Execute read-only SQL query for Claude AI")
User Function ClaudeSQLQuery() as logical
    Local cBody     := oRest:GetBodyRequest()
    Local oReq      := JsonObject():New()
    Local oResp     := JsonObject():New()
    Local xRet      := Nil
    Local cSQL      := ""
    Local nLimit    := CLAUDESQL_MAX_ROWS
    Local cError    := ""
    Local cAlias    := GetNextAlias()
    Local nStart    := Seconds()
    Local nI        := 0
    Local nFields   := 0
    Local nRow      := 0
    Local lTrunc    := .F.
    Local aSchema   := {}
    Local aRows     := {}
    Local aRow      := {}
    Local aStruct   := {}
    Local oCol      := Nil
    Local xVal      := Nil
    Local cDate     := ""
    Local cUser     := ""
    Local bOldError := Nil
    Local oError    := Nil

    // --- Auth check ---
    cUser := RetCodUsr()
    If Empty(cUser)
        oResp['ok']    := .F.
        oResp['error'] := "Autenticacao obrigatoria. Configure Basic Auth no REST server."
        oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
        oRest:setResponse(oResp:ToJson())
        oRest:setStatusCode(401)
        FreeObj(oReq)
        FreeObj(oResp)
        Return .T.
    EndIf

    // --- Parse request body ---
    xRet := oReq:FromJson(cBody)
    If ValType(xRet) == "C"
        oResp['ok']    := .F.
        oResp['error'] := "JSON invalido no body: " + xRet
        oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
        oRest:setResponse(oResp:ToJson())
        oRest:setStatusCode(400)
        FreeObj(oReq)
        FreeObj(oResp)
        Return .T.
    EndIf

    cSQL := AllTrim(cValToChar(oReq['sql']))

    If ValType(oReq['limit']) == "N"
        nLimit := Min(Max(oReq['limit'], 1), CLAUDESQL_MAX_ROWS)
    EndIf

    // --- Audit log (SQL truncado por seguranca) ---
    ConOut("[ClaudeSQL] " + DToC(Date()) + " " + Time() + " | User: " + cUser)
    ConOut("[ClaudeSQL] SQL: " + Left(cSQL, 500) + IIf(Len(cSQL) > 500, "...(truncated)", ""))

    // --- Sanitizar CRLF ---
    cSQL := StrTran(cSQL, Chr(13) + Chr(10), " ")
    cSQL := StrTran(cSQL, Chr(13), " ")
    cSQL := StrTran(cSQL, Chr(10), " ")

    // --- SECURITY: Validate SQL (7 gates) ---
    cError := fValidateSQL(cSQL)
    If !Empty(cError)
        ConOut("[ClaudeSQL] BLOCKED: " + cError)
        oResp['ok']    := .F.
        oResp['error'] := cError
        oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
        oRest:setResponse(oResp:ToJson())
        oRest:setStatusCode(400)
        FreeObj(oReq)
        FreeObj(oResp)
        Return .T.
    EndIf

    // --- Inject TOP limit ---
    cSQL := fApplyTopLimit(cSQL, nLimit)

    // --- ChangeQuery (adapta DBMS) ---
    // Nota: ChangeQuery NAO e homologada para CTEs (WITH) conforme TDN.
    // Chamamos mesmo assim para adicionar FOR READ ONLY e adaptar dialeto.
    // Se falhar em CTE, o erro sera capturado pelo error handler.
    cSQL := ChangeQuery(cSQL)

    bOldError := ErrorBlock({|e| Break(e)})

    Begin Sequence

        MpSysOpenQuery(cSQL, cAlias)

        If Select(cAlias) == 0
            ConOut("[ClaudeSQL] FAIL: alias nao criado")
            oResp['ok']    := .F.
            oResp['error'] := "Query falhou - nenhum resultado retornado. Verifique a sintaxe SQL."
            oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
            oRest:setResponse(oResp:ToJson())
            oRest:setStatusCode(400)
            ErrorBlock(bOldError)
            FreeObj(oReq)
            FreeObj(oResp)
            Return .T.
        EndIf

        // --- Obter estrutura e aplicar TCSetField para tipos corretos ---
        aStruct := (cAlias)->(dbStruct())
        nFields := Len(aStruct)

        For nI := 1 To nFields
            // TCSetField converte campos que MpSysOpenQuery retornaria como char
            If aStruct[nI][2] == "N"
                TCSetField(cAlias, aStruct[nI][1], "N", aStruct[nI][3], aStruct[nI][4])
            ElseIf aStruct[nI][2] == "D"
                TCSetField(cAlias, aStruct[nI][1], "D", 8, 0)
            ElseIf aStruct[nI][2] == "L"
                TCSetField(cAlias, aStruct[nI][1], "L", 1, 0)
            EndIf
        Next nI

        // --- Build schema ---
        For nI := 1 To nFields
            oCol := JsonObject():New()
            oCol['name'] := AllTrim(aStruct[nI][1])
            oCol['type'] := aStruct[nI][2]
            oCol['size'] := aStruct[nI][3]
            aAdd(aSchema, oCol)
        Next nI

        // --- Build rows (array of arrays - compact for LLM) ---
        While !(cAlias)->(Eof()) .And. nRow < nLimit
            aRow := Array(nFields)
            For nI := 1 To nFields
                xVal := (cAlias)->(FieldGet(nI))
                Do Case
                    Case aStruct[nI][2] == "C" .Or. aStruct[nI][2] == "M"
                        aRow[nI] := AllTrim(xVal)
                    Case aStruct[nI][2] == "N"
                        If ValType(xVal) == "N"
                            aRow[nI] := xVal
                        ElseIf ValType(xVal) == "C"
                            aRow[nI] := Val(AllTrim(xVal))
                        Else
                            aRow[nI] := 0
                        EndIf
                    Case aStruct[nI][2] == "D"
                        If ValType(xVal) == "D" .And. !Empty(xVal)
                            cDate := DToS(xVal)
                            aRow[nI] := SubStr(cDate,1,4)+"-"+SubStr(cDate,5,2)+"-"+SubStr(cDate,7,2)
                        ElseIf ValType(xVal) == "C" .And. !Empty(AllTrim(xVal))
                            aRow[nI] := AllTrim(xVal)
                        Else
                            aRow[nI] := ""
                        EndIf
                    Case aStruct[nI][2] == "L"
                        If ValType(xVal) == "L"
                            aRow[nI] := xVal
                        Else
                            aRow[nI] := (AllTrim(cValToChar(xVal)) == ".T.")
                        EndIf
                    Otherwise
                        aRow[nI] := AllTrim(cValToChar(xVal))
                EndCase
            Next nI
            aAdd(aRows, aRow)
            (cAlias)->(DbSkip())
            nRow += 1
        EndDo

        lTrunc := !(cAlias)->(Eof())
        (cAlias)->(DbCloseArea())

        // --- Success response ---
        oResp['ok']        := .T.
        oResp['schema']    := aSchema
        oResp['rows']      := aRows
        oResp['rowCount']  := nRow
        oResp['truncated'] := lTrunc
        oResp['ms']        := Round((Seconds() - nStart) * 1000, 0)

        ConOut("[ClaudeSQL] OK - " + cValToChar(nRow) + " rows in " + cValToChar(oResp['ms']) + "ms")

        oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
        oRest:setResponse(oResp:ToJson())
        oRest:setStatusCode(200)

    Recover Using oError

        ConOut("[ClaudeSQL] ERROR: " + IIf(ValType(oError) == "O", oError:Description, "Unknown"))

        If Select(cAlias) > 0
            (cAlias)->(DbCloseArea())
        EndIf

        oResp['ok']  := .F.
        oResp['ms']  := Round((Seconds() - nStart) * 1000, 0)
        If ValType(oError) == "O"
            oResp['error'] := "Query falhou: " + AllTrim(oError:Description)
        Else
            oResp['error'] := "Query falhou. Verifique sintaxe SQL e nomes de tabela/campo."
        EndIf

        oRest:setKeyHeaderResponse("Content-Type", "application/json; charset=utf-8")
        oRest:setResponse(oResp:ToJson())
        oRest:setStatusCode(500)

    End Sequence

    ErrorBlock(bOldError)

    // Cleanup: liberar JsonObjects do schema
    For nI := 1 To Len(aSchema)
        If ValType(aSchema[nI]) == "O"
            FreeObj(aSchema[nI])
        EndIf
    Next nI

    FreeObj(oReq)
    FreeObj(oResp)
Return .T.


//-------------------------------------------------------------------
// VALIDACAO SQL - 7 gates de seguranca
// Retorna "" se valido, mensagem de erro se bloqueado
//-------------------------------------------------------------------
Static Function fValidateSQL(cSQL as character) as character
    Local cClean    := ""
    Local cNorm     := ""
    Local aBlocked  := {}
    Local nI        := 0
    Local aSysBlocked := { ;
        "SYS.", "MASTER..", "MSDB..", "TEMPDB..", ;
        "INFORMATION_SCHEMA.", "SYSOBJECTS", "SYSLOGINS", ;
        "SYSCOLUMNS", "SYSUSERS", "SYSPROCESSES", ;
        "PG_CATALOG.", "PG_TABLES", "PG_ROLES", "PG_SHADOW", ;
        "PG_USER", "PG_STAT_", "PG_READ_", "PG_LS_", ;
        "DBA_", "V$", "ALL_TAB_", "USER_TAB_", ;
        "MYSQL.", "PERFORMANCE_SCHEMA." ;
    }

    // === GATE 1: Vazio / muito longo ===
    If Empty(cSQL)
        Return "Query SQL e obrigatoria"
    EndIf

    If Len(cSQL) > CLAUDESQL_MAX_SQL
        Return "Query excede tamanho maximo (" + cValToChar(CLAUDESQL_MAX_SQL) + " chars)"
    EndIf

    // === GATE 2: Bloqueia multi-statement (ponto e virgula) ===
    If ";" $ cSQL
        Return "Ponto e virgula nao permitido (prevencao multi-statement)"
    EndIf

    // === GATE 3: Bloqueia comentarios SQL ===
    If "--" $ cSQL
        Return "Comentarios de linha (--) nao permitidos"
    EndIf

    If "/*" $ cSQL
        Return "Comentarios de bloco (/* */) nao permitidos"
    EndIf

    // === GATE 4: Remove string literals para analise segura de keywords ===
    cClean := fStripStringLiterals(cSQL)

    // === GATE 5: Normaliza e valida inicio com SELECT/WITH ===
    cNorm := Upper(AllTrim(cClean))
    cNorm := StrTran(cNorm, Chr(9),  " ")
    cNorm := StrTran(cNorm, "(",     " ")
    cNorm := StrTran(cNorm, ")",     " ")
    cNorm := StrTran(cNorm, ",",     " ")
    cNorm := StrTran(cNorm, "=",     " ")
    cNorm := StrTran(cNorm, "+",     " ")
    cNorm := StrTran(cNorm, "'",     " ")
    cNorm := StrTran(cNorm, '"',     " ")
    While "  " $ cNorm
        cNorm := StrTran(cNorm, "  ", " ")
    EndDo
    cNorm := " " + AllTrim(cNorm) + " "

    If !(" SELECT " $ Left(cNorm, 9)) .And. !(" WITH " $ Left(cNorm, 7))
        Return "Apenas SELECT permitido. Query deve iniciar com SELECT ou WITH."
    EndIf

    // === GATE 6: Bloqueia keywords de escrita/DDL/system ===
    aBlocked := { ;
        "INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE", ;
        "TRUNCATE", "EXEC", "EXECUTE", "MERGE", "GRANT", "REVOKE", ;
        "INTO", "DECLARE", "CURSOR", "DEALLOCATE", "SET", "USE", ;
        "PRINT", "RAISERROR", "THROW", "GOTO", "KILL", "RENAME", ;
        "OPENROWSET", "OPENDATASOURCE", "OPENQUERY", "OPENXML", ;
        "BULK", "SHUTDOWN", "WAITFOR", "DBCC", "RECONFIGURE", ;
        "BACKUP", "RESTORE", "CALL", "LOAD", ;
        "WRITETEXT", "UPDATETEXT", "ENABLE", "DISABLE", ;
        "SLEEP", "BENCHMARK", "OUTFILE", "DUMPFILE" ;
    }

    For nI := 1 To Len(aBlocked)
        If (" " + aBlocked[nI] + " ") $ cNorm
            Return "Keyword bloqueada: " + aBlocked[nI] + " - apenas consultas read-only"
        EndIf
    Next nI

    // Bloqueia stored procedures do sistema
    If " XP_" $ cNorm
        Return "Extended stored procedures (xp_) nao permitidas"
    EndIf

    If " SP_" $ cNorm
        Return "System stored procedures (sp_) nao permitidas"
    EndIf

    // === GATE 7: Bloqueia acesso a tabelas/schemas de sistema ===
    For nI := 1 To Len(aSysBlocked)
        If aSysBlocked[nI] $ cNorm
            Return "Acesso a tabela/schema de sistema bloqueado: " + aSysBlocked[nI]
        EndIf
    Next nI

Return ""


//-------------------------------------------------------------------
// Remove string literals do SQL para analise segura de keywords
// Trata aspas escapadas ('') corretamente
//-------------------------------------------------------------------
Static Function fStripStringLiterals(cSQL as character) as character
    Local cResult := ""
    Local nLen    := Len(cSQL)
    Local nI      := 1
    Local lInStr  := .F.

    While nI <= nLen
        If SubStr(cSQL, nI, 1) == "'"
            If lInStr
                // Aspa escapada '' (literal dentro de string)
                If nI < nLen .And. SubStr(cSQL, nI + 1, 1) == "'"
                    cResult += "  "
                    nI += 2
                    Loop
                Else
                    cResult += " " // Fecha string
                    lInStr := .F.
                EndIf
            Else
                cResult += " " // Abre string
                lInStr := .T.
            EndIf
        Else
            If lInStr
                cResult += " " // Conteudo de string vira espaco
            Else
                cResult += SubStr(cSQL, nI, 1)
            EndIf
        EndIf
        nI += 1
    EndDo

Return cResult


//-------------------------------------------------------------------
// Adiciona TOP N ao SELECT se nao estiver presente
// Para CTEs (WITH), nao injeta TOP - o loop de leitura limita as rows
//-------------------------------------------------------------------
Static Function fApplyTopLimit(cSQL as character, nLimit as numeric) as character
    Local cUpper := ""
    Local cNorm  := ""
    Local nPos   := 0
    Local cTop   := " TOP " + cValToChar(nLimit) + " "

    cUpper := Upper(AllTrim(cSQL))

    // Normaliza espacos para detectar TOP/LIMIT/FETCH existente
    cNorm := StrTran(cUpper, Chr(9), " ")
    While "  " $ cNorm
        cNorm := StrTran(cNorm, "  ", " ")
    EndDo

    // Ja tem TOP, LIMIT ou FETCH? Respeita o existente
    If "SELECT TOP " $ cNorm .Or. "SELECT DISTINCT TOP " $ cNorm
        Return cSQL
    EndIf
    If " LIMIT " $ cNorm .Or. " FETCH " $ cNorm
        Return cSQL
    EndIf

    // CTE (WITH ...): nao injeta TOP - estrutura complexa e fragil.
    // O loop de leitura (While nRow < nLimit) ja limita as rows lidas.
    If Left(cUpper, 4) == "WITH"
        Return cSQL
    EndIf

    // SELECT simples -> injeta TOP apos SELECT
    nPos := At("SELECT", cUpper)
    If nPos > 0
        // SELECT DISTINCT?
        If SubStr(AllTrim(SubStr(cUpper, nPos + 6)), 1, 8) == "DISTINCT"
            nPos := nPos + At("DISTINCT", SubStr(cUpper, nPos)) - 1
            Return Left(cSQL, nPos + 7) + cTop + SubStr(cSQL, nPos + 8)
        Else
            Return Left(cSQL, nPos + 5) + cTop + SubStr(cSQL, nPos + 6)
        EndIf
    EndIf

Return cSQL
```

## Notas tecnicas para o Claude

- **oRest NAO pode ser passado para Static Functions** em TLPP REST. Todas as chamadas a `oRest:setResponse()` e `oRest:setStatusCode()` devem ser feitas diretamente na User Function anotada com @Get/@Post.
- A annotation REST deve usar o formato `@Post(endpoint="/path", description="...")` com `endpoint=` nomeado. O formato posicional `@Post("/path")` pode nao funcionar em todas as versoes do AppServer.
- `ChangeQuery()` deve ser chamada antes de `MpSysOpenQuery()` (MpSysOpenQuery NAO chama ChangeQuery internamente).
- `TCGetDB()` retorna: `"MSSQL"`, `"ORACLE"`, `"POSTGRES"`, `"DB2"` conforme o banco conectado.
- O health endpoint retorna o tipo do banco em `database` para que o Claude adapte a sintaxe SQL.
