# Construir queries — padroes por cenario

## Conteudo
- Hierarquia de APIs de execucao
- FWExecStatement / FWPreparedStatement (metodos, reuso de statement)
- Embedded SQL (tags, limitacoes)
- MPSysOpenQuery / MPSysExecScalar
- TCSqlToArr
- DML com TCSQLExec
- FWBulk (carga em massa)
- Tabelas temporarias (FWTemporaryTable / SharedTable)
- Banco externo (FWDBAccess)
- Workarea (quando ainda e a escolha certa)

## Hierarquia de APIs (o que usar em codigo novo)

| API | Papel | Status |
| --- | --- | --- |
| `FWExecStatement` | Default para SELECT novo — bind real no SGBD, reuso de plano de execucao (lib >= 20211116) | Recomendado |
| `FWPreparedStatement` | Classe-base; use quando so precisa da string final (`getFixQuery`) ou de conexao externa (`setConnection`) | Valido |
| `MPSysOpenQuery` / `MPSysExecScalar` | Alternativa funcional enxuta (aBindParam a partir da lib 20211116); NAO aplica ChangeQuery — responsabilidade do dev | Valido |
| Embedded SQL (`BeginSql/EndSql`) | Query estatica e legivel; ChangeQuery automatica | Valido |
| `TCGenQry2` | Motor por baixo do FWExecStatement; nao e o nivel de escrita | Baixo nivel |
| `dbUseArea(.T.,"TOPCONN",TCGenQry(...))` e comando `TCQUERY ... NEW` | Sem bind, sem cache | Evitar em codigo novo |

## FWExecStatement / FWPreparedStatement

Metodos de bind (parametros SEMPRE comecam em 1):

```
setString(n, cValue)      // sem aspas simples no valor — aspas viram parte da string
setNumeric(n, nValue)
setDate(n, dDate)
setBoolean(n, lValue, [lProtheus=.T.])
setIn(n, aValues)         // monta o IN (...)
setUnsafe(n, xValue)      // SEM escape — so identificadores internos, nunca input externo
setParams(aParams)        // menos performatico (usa ValType)
```

Execucao:
- `OpenAlias([cAlias],[cLifeTime],[cTimeout]) -> cAlias` — cursor; cache DBAPI se lifetime+timeout (ambos, como caractere, em segundos)
- `ExecScalar(cColumn,[cLifeTime],[cTimeout]) -> xValue` — um valor
- `getFixQuery() -> cQuery` — query com valores ja substituidos (lado aplicacao); util para `TCSqlExec(oStmt:GetFixQuery())`
- `getResultArray(cAlias, [lClose=.T.])` — NAO faz DBGoTop; le da posicao atual

Liberacao: `(cAlias)->(DbCloseArea())` + `oStmt:Destroy()` + `FwFreeObj(oStmt)`.

### Reuso de statement (padrao mais moderno do codigo-padrao, FISA164/166)

Para query executada repetidamente na mesma thread, cachear o statement em vez de destruir:

```advpl
Static jPrepared
If Valtype(jPrepared) <> 'J'
    jPrepared := JsonObject():new()
EndIf
cMD5 := MD5(cQuery)
If Valtype(jPrepared[cMD5]) <> 'O'
    jPrepared[cMD5] := FwExecStatement():New(ChangeQuery(cQuery))
EndIf
For nI := 1 To Len(aBind)
    jPrepared[cMD5]:setString(nI, aBind[nI])
Next
cAlias := jPrepared[cMD5]:OpenAlias()
```

Invalidar o cache quando `cEmpAnt` mudar. Nao usar `oQry:cBaseQuery := oQry:GetFixQuery()` (propriedade nao documentada vista em alguns fontes — nao replicar).

## ChangeQuery — obrigatoria, salvo casos especiais

Sempre ANTES do `New()`. O que faz: normaliza espacos, REMOVE `NOLOCK`, traduz `SUBSTRING` e `||`, corrige `= ''` para `= ' '`, injeta `FOR READ ONLY` (DB2), ORDER BY nominal->ordinal (Informix/DB2-AS400). Limites: quebra com palavra reservada dentro de nome/conteudo de campo (`ZZZ_FROM` vira `ZZZ_ FROM` — mitigacao: FWPreparedStatement); maximo 99 sub-selects. `FWAdapterBaseV2` NAO usa ChangeQuery (tratar concatenacao/funcoes manualmente la).

## Embedded SQL

```advpl
Local cAlias := GetNextAlias()
BeginSql Alias cAlias
    SELECT E1_NUM, E1_VALOR
    FROM %table:SE1% SE1
    WHERE SE1.E1_FILIAL = %xfilial:SE1%
      AND SE1.E1_CLIENTE = %exp:cCliente%
      AND SE1.%notDel%
    ORDER BY %Order:SE1%
EndSql
```

Tags: `%table:ALIAS%` (RetSqlName) · `%temp-table:cVar%` · `%xfilial:ALIAS%` · `%notDel%` (D_E_L_E_T_=' ') · `%exp:expr%` (escapa o valor; aceita JSON via :toJson a partir da lib 20230403) · `%Order:ALIAS[,n|,nick]%` (SqlOrder do indice) · `%noparser%` (desliga ChangeQuery) · `column X as Date/Logical/Numeric(t,d)` (TCSetField).

Limitacoes que decidem contra o Embedded:
- `?` e caractere reservado — query ou valores com `?` => usar FWExecStatement
- Funcao AdvPL no meio do bloco: proibida (guardar em variavel antes; exceto dentro de `%exp:%`)
- `EndSql` alinhado a esquerda (senao C2001); `*` nao pode abrir linha; nao depuravel (breakpoints ignorados)
- Diagnostico: `GetLastQuery()` -> `[2]` query executada, `[5]` tempo em segundos

## MPSysOpenQuery / MPSysExecScalar

```advpl
cAlias := MPSysOpenQuery(cQuery, /*cAlias*/, /*aSetField*/, /*cDriver*/, {xFilial("SE1"), cCliente, " "})
xVal   := MPSysExecScalar(cQuery, "TOTAL", aBind)
```
Alias default = GetNextAlias(); se o alias ja existir e FECHADO antes. NAO aplica ChangeQuery. Nunca dentro de loop (recomendacao oficial).

## TCSqlToArr — resultado pequeno sem workarea

```advpl
nRet := TCSqlToArr(cQuery, @aResult, aBinds, aSetFields)   // DBAccess >= 22.1.1.0
```
Bind nativo, sem alias. Ideal para APIs que montam JSON de poucas linhas.

## DML — TCSQLExec

```advpl
If TCSqlExec(oStmt:GetFixQuery()) < 0
    ConOut("[ROTINA] Erro SQL: " + TCSQLError())
EndIf
```
Uma instrucao por vez; retorno `< 0` NAO gera erro AdvPL (checar sempre); NAO atualiza campos de controle do DBAccess (R_E_C_N_O_ etc. por conta do dev). Validacoes e gatilhos de dicionario nao executam aqui — nem em RecLock; quem os dispara e a camada ExecAuto/MVC. CRUD comum: prefira Workarea RecLock/MsUnlock (ou MsExecAuto quando validacoes/gatilhos importam).

## FWBulk — carga em massa

30-40% mais rapido que insercao unitaria (lib >= 20201009 + DBAccess >= 20181212). `CanBulk()` e estatico e retorna .F. em SQLite — implementar fallback RecLock. `SetOption()` (ajuste de decimais) a partir da lib 20250630 + DBAccess 24.1.0.1.

## Tabelas temporarias

- `FWTemporaryTable` — nome gerado, dropada no logout. `GetTableNameForQuery()` para usar em query; `Zap()` (lib 20220321); `SetClobMemo()` (lib 20220613). Nao suportam TCAlter; criar indices APOS inserir dados; transacao NAO garantida em MSSQL (Oracle/Postgres sim).
- `totvs.framework.database.temporary.SharedTable` — temporaria visivel ENTRE threads (lib >= 20230109); mesmos metodos.
- Popular a partir do banco: `INSERT INTO <temp>(...) SELECT ...` via TCSQLExec — o banco insere sem trafegar dados pela aplicacao.

## Banco externo — FWDBAccess

```advpl
oDB := FWDBAccess():New("MSSQL/ALIAS_EXTERNO", cServer, nPort)
oDB:OpenConnection()
oStmt := FWPreparedStatement():New(cQuery)
oStmt:setConnection(oDB)
// ... NewAlias / SQLExec / SPExec / TransBegin-TransEnd ...
oDB:CloseConnection()
oDB:Finish()          // indispensavel
```

## Workarea — quando ainda e a escolha certa

Lookup de 1 registro por chave de indice SIX e CRUD simples (para CRUD que exige validacoes/gatilhos de dicionario, use `MsExecAuto` — RecLock direto nao os dispara):

```advpl
DbSelectArea("SA1")
SA1->(DbSetOrder(1))                          // A1_FILIAL+A1_COD+A1_LOJA
If SA1->(DbSeek(xFilial("SA1") + cCod + cLoja))
    RecLock("SA1", .F.)
    SA1->A1_NOME := cNome
    SA1->(MsUnlock())
EndIf
```
Sempre `GetArea()`/`RestArea()` em volta quando a rotina nao e dona do posicionamento. Para conjuntos grandes, SQL — nunca dbSkip em massa.
