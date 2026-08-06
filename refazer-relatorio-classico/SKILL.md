---
name: refazer-relatorio-classico
description: >-
  Reaproveitar/refazer um relatório CLÁSSICO padrão TOTVS (FINRxxx, MATRxxx,
  COMRxxx, FATRxxx…) como uma cópia CUSTOMIZADA que compila SEM chave de
  compilação. Obtém o fonte do relatório (MCP de referência TOTVS
  `advpl-tlpp-mcp-docs`, ou onde o usuário indicar), remove a
  trava de descontinuação (`VldDescRel`, release 12.1.2510+), renomeia a função
  principal para `User Function` com prefixo `z`, as demais para
  `Static Function` com `z`, converte `StaticCall` em macro-execução `&(...)`, e
  copia o `.ch` para a pasta include do Protheus. Usar quando o cliente pede de
  volta um relatório clássico que foi substituído pelo Smart View (ou quando a
  rotina padrão saiu do RPO). NÃO usar para criar relatório do zero.
---

# Refazer relatório clássico (reaproveitamento sem chave de compilação)

Traz um relatório clássico padrão TOTVS de volta como fonte **customizado**
compilável no ambiente do cliente **sem chave de compilação**. A técnica: dar a
todas as funções um prefixo (`z`) para não colidir com o padrão do RPO, expor a
principal como `User Function` (`U_z...`), e diferir `StaticCall` para runtime
via macro-execução.

## Arquivos desta skill

| Arquivo | Papel |
|---|---|
| `refazer-relatorio.ps1` | Engine: transforma o fonte in-place (`-DryRun`, `-Prefix`, `-SkipComments`) |
| `validar-relatorio.ps1` | Validação pós-engine, PASS/FAIL + exit 2 (`-IncludeDir`) |
| `lib-segmentos.ps1` | Separa código × comentário e preserva a largura das caixas. Dot-source dos dois acima — **não rodar direto** |

## Pré-requisitos / entradas

1. **Código do relatório clássico** (ex.: `FINR130`, `MATR320`). Se o usuário só
   souber o nome ("Títulos a Receber"), descobrir o código clássico primeiro
   (TDN, MCP `advpl-tlpp-mcp-docs`, ou de-para Smart View ↔ clássico).
2. **Fonte do relatório** — em ordem de preferência:
   - **a) MCP `advpl-tlpp-mcp-docs`** (`get-code-chunks` por `filename="<CODIGO>.PRX"`
     ou `name="<CODIGO>"`): é a base de referência TOTVS, disponível a quem usa a
     skill. **Conferir se veio COMPLETO** — o índice é por símbolo e pode não trazer
     o cabeçalho (`#include`, `#define`, `Static` de escopo de arquivo); se faltar,
     complementar ou usar (b). A versão do MCP normalmente já vem **com** a trava
     `VldDescRel` — tudo bem, o engine remove.
   - **b) Se o MCP não tiver o relatório (ou vier incompleto): PERGUNTAR ao usuário
     onde está o fonte completo** (`.prx`/`.prw`) e o `<codigo>.ch`. Normalmente é
     baixado do **Portal do Cliente TOTVS** (área de fontes dos relatórios
     descontinuados). **Não assumir nenhuma pasta** — cada ambiente é um.

   O `<codigo>.ch` (defines de `STRxxxx` via `FWI18NLang`) acompanha o fonte. Os
   `.tres` (tradução) **não** precisam ser copiados — já estão no RPO.
3. **Repo do projeto** + **pasta include do Protheus** — PERGUNTAR/confirmar com o
   usuário (variam por ambiente, não fixar):
   - destino do fonte: `src/<modulo>/relatorios/` (`modulo` conforme o relatório:
     financeiro, estoque, compras, faturamento…);
   - pasta include: a `\include` da instalação do Protheus do ambiente
     (ex.: `<...>\Protheus\include`) — passar via `-IncludeDir` nos scripts.

## Regras que este processo respeita (não quebrar)

- **Remover a TRAVA de descontinuação** (é o motivo #1 dos clássicos pararem). A
  partir do release **12.1.2510**, a TOTVS injeta no topo da função principal:
  ```advpl
  //Validação de aviso/bloqueio do relatório em Release 12.1.2510 e superiores
  If ExistFunc("VldDescRel")
      If !VldDescRel()
          Return
      EndIf
  EndIf
  ```
  `VldDescRel()` retorna `.F.` no release bloqueado → o relatório dá `Return` sem
  rodar. A função é **universal** (mesmo nome em FINR/MATR/COM…). O engine
  **remove esse bloco automaticamente** (troca por um comentário-marcador) e o
  validador **falha** se sobrar uso ativo de `VldDescRel`. Fontes baixados do
  portal ANTES da trava não têm o bloco (nesse caso o engine remove 0 e segue).
- **Prefixo `z`** em TODAS as funções do fonte; o entry-point vira `User Function`,
  as demais `Static Function`. (Evita `C2021 Redefinition` contra o RPO padrão.)
  Uma `User Function` que já exista no fonte é **mantida** — ver a nota de
  entry-point no passo 3.
- **Regra dos 10 caracteres** (`advpl-nome-funcao-10-caracteres`): os **símbolos**
  gerados devem ser distintos nos 10 primeiros chars — `User Function X` gera
  `U_X`, as demais geram `X`. O engine checa e ABORTA (exit 2) se houver colisão;
  nesse caso renomear a função ofensora manualmente e rodar de novo.
- **`StaticCall(A,B)` → `&("StaticCall(A,B)")`**: sem chave de compilação, o
  `StaticCall` para static de outro fonte padrão não linka; a macro `&(...)`
  compila em runtime (não precisa de chave). Confirmado pelo usuário como a
  técnica correta.
- **Código e comentário têm regras DIFERENTES.** O engine separa os dois antes de
  renomear (`lib-segmentos.ps1`); sem essa separação o cabeçalho padrão TOTVS sai
  meio renomeado e com a caixa torta.
  - **No código**: renomeia declaração, `Nome(` e `U_Nome(`. Não toca alias de
    work-area (`FTITPAI->`) nem `#include` — nenhum tem `(` logo após o nome.
    Strings **continuam** valendo como código de propósito: `&("zFoo()")` precisa
    do prefixo para a macro achar a função.
  - **No comentário**: renomeia o nome **mesmo sem `(`** — é o formato do
    cabeçalho box-art (`│Funçäo │ FINR130 │`, `│Sintaxe │ FINR130(void) │`).
    Em linha de caixa o engine **reabsorve o caractere a mais comendo um espaço
    da folga** (nunca um TAB, nunca juntando palavra), para a borda direita não
    sair de coluna. Sem folga, avisa o número da linha.
  - `-SkipComments` desliga a parte de comentário, se algum dia atrapalhar.
- **NÃO editar o `.ch`**: copiar verbatim. As `STRxxxx` resolvem em runtime via
  `FWI18NLang("<CODIGO>", ...)` contra os `.tres` padrão já presentes no RPO.
- **Dicionário**: este processo NUNCA cria SX1/SX3/SX6. Os relatórios reusam o
  grupo de perguntas padrão (`Pergunte("MTR320",…)` etc.), que já existe no
  dicionário do cliente. (Ver regra `protheus-dicionario`.)

## Processo

### 1. Obter o fonte e o `.ch`
1. Descobrir o **código clássico** do relatório (ver Pré-requisitos 1).
2. Buscar o fonte no **MCP** `advpl-tlpp-mcp-docs` (`get-code-chunks`). Se o MCP
   não tiver, ou o retorno vier **incompleto** (sem cabeçalho / faltando funções),
   **perguntar ao usuário** onde está o `.prx`/`.prw` completo e o `.ch`
   (Pré-requisitos 2). Nunca chutar uma pasta.

### 2. Colocar o fonte no repo (como z<codigo>.prw)
Gravar o fonte **completo** em `<repo>\src\<modulo>\relatorios\z<codigo>.prw`
(sempre `.prw` minúsculo, prefixo `z`), preservando **encoding** (CP1252/box-art)
e **CRLF**:
- Fonte é um **arquivo** do usuário (`.prx`/`.prw`): copiar byte-a-byte com
  `mcp__file-tools__copy_file` (falha se o destino já existir).
- Fonte veio do **MCP** (texto): gravar com `mcp__file-tools__write_file`
  (`encoding: cp1252`), incluindo cabeçalho (`#include`/`#define`) e TODAS as
  funções. Conferir que ficou completo (contagem de funções, `#include`) antes de
  seguir.

### 3. Transformar (engine PowerShell)
Rodar o engine `refazer-relatorio.ps1` (mesma pasta desta skill). Ele faz, nesta
ordem: (0) **remove a trava `VldDescRel`**; (1) separa código × comentário e
detecta as funções — só as declaradas em **código**, para não pegar código
comentado; (2) checa a regra dos 10 chars; (3) num passe único por linha:
`StaticCall` → macro, prefixa declaração / `Nome(` / `U_Nome(` no código, prefixa
o nome nos comentários e **reajusta a largura das linhas de caixa**; ajusta a
palavra-chave (`User`/`Static Function`) na mesma passada.
**Sempre `-DryRun` primeiro** para conferir funções detectadas, trava removida e
regra dos 10 chars, e só então aplicar:
```powershell
# dry-run (não grava; mostra funções, StaticCall e colisão)
& "<skill>\refazer-relatorio.ps1" -Path "<repo>\src\<modulo>\relatorios\z<codigo>.prw" -DryRun
# aplicar
& "<skill>\refazer-relatorio.ps1" -Path "<repo>\src\<modulo>\relatorios\z<codigo>.prw"
```
Se o dry-run acusar **colisão de 10 chars**, resolver manualmente (renomear a
função ofensora com sufixo curto) antes de aplicar.

> **Entry-point**: se o fonte **já tem** uma `User Function`, ela é o entry-point e
> o engine a mantém (não cria uma segunda). Se não tem, a **1ª declaração** vira a
> `User Function` — caso normal do TReport clássico (`Function <CODIGO>()` no topo).
> Isso cobre o clássico que declara um wrapper `Function TECR012()` chamando
> `U_TECR012()`: o wrapper vira `Static Function zTECR012()` e passa a chamar
> `U_zTECR012()` (a NOSSA cópia, não a padrão do RPO). Sem esse tratamento saíam
> duas `User Function` de mesmo nome → `C2021` na compilação.

### 4. Copiar o include (.ch) — VERBATIM, sem editar
Para a pasta include do Protheus do ambiente (fora do sandbox do file-tools; use
PowerShell). Confirmar o caminho da `\include` com o usuário:
```powershell
Copy-Item "<fonte>\<codigo>.ch" "<pasta include do Protheus>\<codigo>.ch" -Force
```
Includes **padrão** referenciados (`PROTHEUS.CH`, `FWCOMMAND.CH`,
`FWLIBVERSION.CH`, …) já existem no RPO — não copiar. Conferir com um
`Test-Path` quais faltam.

### 5. Validar pós-engine (OBRIGATÓRIO)

O engine é mecânico; a validação abaixo fecha **todas as falhas verificáveis sem
compilar**. Rodar SEMPRE após o engine (e após copiar o `.ch`):

```powershell
& "<skill>\validar-relatorio.ps1" -Path "<repo>\src\<modulo>\relatorios\z<codigo>.prw" -IncludeDir "<pasta include do Protheus>"
```
(`-IncludeDir` é opcional; sem ela, a checagem de includes é pulada com `SKIP`.)

O script (`validar-relatorio.ps1`) reporta PASS/FAIL e **exit 2** se algo falhar.
Ele usa a mesma separação código × comentário do engine, então comentário nunca
dispara checagem de código (e vice-versa). Checagens:
1. Todas as funções com prefixo `z`.
2. Exatamente **1** `User Function` (o entry-point).
3. Nenhuma `Function` pública sobrando (todas `Static`, fora a principal).
4. Regra dos **10 caracteres** (colisão C2021) sobre o **símbolo gerado** —
   `User Function X` gera `U_X`, as demais geram `X`. São espaços distintos: um
   fonte com `Static Function zTECR012` **e** `User Function zTECR012` não colide.
5. **Nenhuma chamada crua** das próprias funções — pega tanto `Nome(` quanto
   `U_Nome(` (esta última chamaria a função PADRÃO do RPO, não a cópia).
6. `StaticCall` → `&("StaticCall(…)")` (nenhum cru).
7. **Trava `VldDescRel` removida** (sem uso ativo — senão o relatório nasce
   travado no release 12.1.2510+ e dá `Return` sem rodar).
8. **Perigo real**: nenhuma função própria (agora `Static`) executada **por nome**
   em `&("z…(")` / `ExecBlock("z…")` — macro **não enxerga** `Static`. Se aparecer,
   converter essa função de volta para `User Function` (ou tratar caso a caso).
   Passar a função como argumento (`&(cVar):Set(zFoo(x))`) **não** é perigo: ali
   `zFoo` é código compilado, não faz parte da macro.
9. Fim de linha **CRLF** (sem LF solto — gotcha `Syntax Error` do AdvPL,
   ver [[advpl-lf-crlf-syntax-error]]).
10. Todos os `#include` referenciados existem na pasta include.
11. **AVISO** (não reprova): comentário que ainda cita o nome antigo. Só afeta
    documentação, nunca compilação.

> Só aceite avançar com **RESULTADO: PASS**. Qualquer FAIL: corrigir antes de
> compilar (renomear função em colisão de 10 chars; reprefixar call site perdido;
> reverter para `User Function` a que é chamada por macro; copiar include que falta).

> **Fonte com LF solto acontece de verdade** — ~8% dos fontes do portal vêm com
> quebra `LF` em vez de `CRLF`. O engine **normaliza sozinho** e informa quantas
> linhas converteu (`-KeepEol` desliga, mas aí o item 9 reprova).

### 6. Conferência visual (diff) — recomendado

Para ter certeza de que o engine **só** mexeu em nome/declaração de função (e nada
mais), rodar um diff do fonte **original** (antes do engine) contra o transformado.
Guardar uma cópia do original antes de transformar (se veio do MCP, salvar o texto
puro num arquivo temporário):

```powershell
git diff --no-index --ignore-cr-at-eol "<fonte original>" "<repo>\src\<modulo>\relatorios\z<codigo>.prw"
```

Toda linha `-/+` deve ser uma destas três: declaração/chamada de função com prefixo
`z`; o wrap do `StaticCall`; ou linha de **comentário** onde só o nome ganhou o `z`
(nas linhas de caixa, com a largura preservada — confira que a borda direita
continua na mesma coluna das linhas vizinhas). `#include`, alias `Nome->`, ID do
TReport e args literais ficam idênticos. Qualquer outra mudança, investigar.

### 7. Compilar e testar (única prova 100%)

As checagens 5–6 são mecânicas; a prova final é compilar e executar no ambiente:
1. Compilar **1** fonte (o menor primeiro). Nomes têm prefixo `z` → **sem chave**.
   - Aceitável: *warning* de "unused static function" (funções mortas: índice
     legado, `Eng##Compile`/`##Signature` de stored procedure). Não é erro.
   - Erro `C2021 Redefinition of FXXXXXXXXX` = colisão de 10 chars → a validação
     item 4 já teria pego; renomear a função e recompilar.
2. Executar direto no SmartClient com programa inicial `U_z<CODIGO>` (ou incluir
   no menu apontando para essa função).
3. Conferir que abre o `PrintDialog` e imprime.

**Dependências de runtime** (não introduzidas por nós — o clássico já as exigia e
já as tinha no RPO do cliente): stored procedures (ex.: MAT056/FIN002), RDMAKEs
externos chamados por `ExecBlock` (ex.: `F620QRY`, `FR150FLT`, `F130QRY`,
`FR130TELC`) e grupos de pergunta SX1. **Se o relatório clássico rodava nesse
cliente, a cópia `z` roda igual.**

### 7.1 Relatório chamado por rotina padrão via parâmetro `MV_*` — shim PARAMIXB (OBRIGATÓRIO)

Vários clássicos não são chamados só pelo menu: a rotina padrão os invoca por um
parâmetro SX6 que aponta para um RDMAKE de usuário. O fonte padrão sempre segue
esta forma (exemplo do `mata120.prx`, validado via MCP):

```advpl
Function A120Impri( cAlias, nRecno, nOpc )         // funcao de impressao da rotina
Local cPrinter := SuperGetMv("MV_PCOMPRA" ,, "")   // parametro aponta o RDMAKE
If !Empty( cPrinter ) .And. ExistBlock( cPrinter )
    ExecBlock( cPrinter, .F., .F., { cAlias, nRecno, nOpc } )  // rotina de USUARIO
Else
    MATR110( cAlias, nRecno, nOpc )                            // padrao: posicional
EndIf
```

**Consequência:** ao apontar o `MV_*` para a cópia `z` (valor **sem** `U_`, ex.:
`ZMATR110`), a chamada vira **ExecBlock** → os argumentos chegam na private
**`PARAMIXB`** e os parâmetros posicionais da `User Function` chegam **Nil**.
No MATR110 isso zera `lAuto := (nReg != Nil)` e o relatório passa a imprimir pela
**faixa de perguntas** em vez do **registro selecionado** no browse.

**Rotinas que usam esse mecanismo** (levantado com `code-search` no MCP
`advpl-tlpp-mcp-docs` sobre os fontes padrão):

| Rotina | Função de impressão | Parâmetro SX6 | O que vai no `ExecBlock` |
|---|---|---|---|
| MATA110 | `A110Impri(cAlias,nRecno,nOpc)` | `MV_SOLIMPR` | `{ cAlias, nRecno, nOpc }` |
| MATA113 | `A113Impri(cAlias,nRecno,nOpc)` | `MV_SOLIMPR` | `{ cAlias, nRecno, nOpc }` |
| MATA120 | `A120Impri(cAlias,nRecno,nOpc)` | `MV_PCOMPRA` | `{ cAlias, nRecno, nOpc }` |
| MATA123 | `A123Impri(cAlias,nRecno,nOpc)` | `MV_PCOMPRA` | `{ cAlias, nRecno, nOpc }` |
| MATA103 | `A103Impri(cAlias,nRecno,nOpc)` | `MV_PIMPNFE` | `{ cAlias, nRecno, nOpc }` |
| MATA125 | `A125Impri(cAlias,nRecno,nOpcx)` | `MV_CONTPAR` | `{ cAlias, nRecno, nOpcx }` — e **usa o retorno** do ExecBlock |
| MATA105 | `A105Imprim(cAlias,nReg,nOpcx)` | `MV_RELSALM` | **`{ SCP->CP_EMISSAO, SCP->CP_NUM }`** — conteúdo diferente! |
| MATA415 | `A415Impri()` | `MV_ORCIMPR` | **sem argumentos** — depende do registro posicionado |
| LOJA010 | `lj010Orc()` | `MV_SCRORC` / `MV_SCRPED` | **sem argumentos** |

**Nunca presuma o conteúdo do `PARAMIXB`** — as duas últimas linhas da tabela
mostram por quê: o MATA105 passa **campos** (`CP_EMISSAO`, `CP_NUM`), não
alias/recno; MATA415 e LOJA010 não passam nada. Antes de escrever o shim,
confirme o contrato da **sua** rotina:

1. No MCP `advpl-tlpp-mcp-docs`, `code-search` por `"<ROTINA>Impri MV_ ExecBlock"`
   (ex.: `"A120Impri MV_PCOMPRA ExecBlock"`).
2. Leia o array do `ExecBlock`: ele é **exatamente** o conteúdo de `PARAMIXB`, na ordem.
3. Mapeie cada posição para os parâmetros da sua cópia `z`.

**Correção (caso com argumentos)** — inserir logo após os `Local` da função
principal, ANTES de qualquer uso dos parâmetros (no MATR110, antes do
`Private lAuto := (nReg!=Nil)`):

```advpl
// Quando chamado via MV_PCOMPRA, a rotina padrao (A120Impri) executa este relatorio
// por ExecBlock; nesse caso os parametros chegam pela variavel private PARAMIXB e nao
// posicionalmente. Recupera cAlias/nReg/nOpcx antes de calcular lAuto e os filtros.
If nReg == Nil .And. Type("PARAMIXB") == "A"
	cAlias := PARAMIXB[1]
	nReg   := PARAMIXB[2]
	nOpcx  := PARAMIXB[3]
EndIf
```

Ajuste os índices ao contrato levantado no passo 2 — no MATA105, por exemplo,
`PARAMIXB[1]` é a **emissão** e `PARAMIXB[2]` o **número**, e o shim teria de
posicionar o registro a partir desses campos em vez de atribuir alias/recno.

**Caso sem argumentos** (MATA415, LOJA010): não há `PARAMIXB` para recuperar. O
shim é desnecessário, mas os parâmetros posicionais **continuam chegando `Nil`** —
garanta um default sensato e lembre que o relatório depende do **registro
posicionado** pela rotina chamadora.

O shim é inócuo na execução avulsa pelo menu (sem `PARAMIXB` a condição é falsa e
o comportamento por perguntas se mantém). Ao testar (passo 7), exercitar **os dois
caminhos**: menu (`U_z<CODIGO>`) e a rotina padrão com o `MV_*` apontado para a
cópia `z`.

### 8. Observação — traduções (`STRxxxx`)
Se ao executar algum `STRxxxx` sair **em branco**, é porque o recurso `.tres`
padrão não resolveu via `FWI18NLang`. Solução: aplicar a expedição do módulo, ou
substituir os `STRxxxx` por literais no fonte. Não é motivo para copiar `.tres`
(eles já vêm no RPO padrão).

## Exemplo real (4 relatórios reaproveitados)

Um de-para Smart View → clássico levou a 4 relatórios reaproveitados:

| Smart View não disponível | Clássico | Destino no repo | Funções |
|---|---|---|---|
| Movimento Bancário (FINSV021) | **FINR620** | `src/financeiro/relatorios/zfinr620.prw` | 7 |
| Títulos a Receber (FINSV005) | **FINR130** | `src/financeiro/relatorios/zfinr130.prw` | 27 (1 StaticCall) |
| Títulos a Pagar (FINSV013) | **FINR150** | `src/financeiro/relatorios/zfinr150.prw` | 12 (1 StaticCall) |
| Entradas e Saídas (ESTSV017) | **MATR320** | `src/estoque/relatorios/zmatr320.prw` | 5 |

Caso instrutivo (FINR130): `FTITPAI` é ao mesmo tempo **função** (`FTITPAI()`) e
**alias** de work-area (`'FTITPAI'`, `FTITPAI->`). A regra `Nome(` renomeou só
a função (`zFTITPAI()`), deixando o alias intacto — exatamente o desejado.

Segundo caso instrutivo (também FINR130): o fonte tem **29 linhas de cabeçalho
box-art**. Antes da separação código × comentário, as 7 que traziam o nome com
parêntese (`│Sintaxe e │ FINR130(void)`) eram renomeadas e ganhavam 1 coluna —
borda direita da caixa torta —, enquanto as 18 que traziam o nome sem parêntese
(`│Funçào │ FINR130 │`) ficavam documentando uma função que não existia mais.
Hoje as 29 saem renomeadas e com a largura original.

Caso instrutivo (MATR110): chamado pelo MATA120 via `MV_PCOMPRA` → sem o shim
`PARAMIXB` da seção 7.1 ele "funciona", mas imprime pela faixa de perguntas em vez
do pedido selecionado no browse. Confirmado em produção em duas implantações.
