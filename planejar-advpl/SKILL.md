---
name: planejar-advpl
description: Use when starting a new Protheus customization or feature, or mentions "planejar", "planejar advpl", "nova feature", "nova customizacao", "planejar customizacao". Guides through 8 stages - idea, research, interrogation, PRD, kanban, QA, pre-production cleanup, and production deploy for ADVPL/TLPP development.
---

# Planejar ADVPL

Skill de processo para planejar e acompanhar o desenvolvimento de features/customizacoes Protheus, da ideia ao QA.

## Retomada

Ao ser invocada, SEMPRE verifique primeiro se existe um plano em andamento:

1. Liste `.claude/plans/` para ver planos existentes
2. Se o usuario mencionar uma feature existente, leia o `plano.md` correspondente
3. Retome da etapa atual indicada no `plano.md`
4. Se existir `wayfinder-map.md` na pasta do slug: leia-o antes de tudo — "Decisions so far" sao decisoes JA tomadas (a Etapa 3 pergunta apenas o que estiver aberto; o PRD sintetiza delas), as linhas de "Out of scope" do mapa vao para a secao `## Fora de escopo / rejeitado` do plano.md, e o "Destination" vira o `## Escopo declarado` (E-1..E-n com fonte)
5. Se o plano ja estiver na Etapa 5 ou depois: leia `ETAPA-5-KANBAN.md` antes de tocar em qualquer card — o **modo de aprovacao** e perguntado de novo a cada sessao, os comentarios novos nos cards ativos sao lidos antes de decidir o que fazer, e o que espera terceiro ha mais de 3 dias uteis e listado ao usuario de saida
6. Se nao existir plano, inicie pela Etapa 1

## Auto-sizing: a complexidade determina a profundidade

O processo nao tem um peso unico. Dimensione pelas respostas da Etapa 1 (ou pelo argumento do usuario, ex: "escopo pequeno"):

| Porte | Sinais | Etapas |
|-------|--------|--------|
| **Pequeno** | <= 3 fontes, escopo cabe em 1 frase, causa/solucao conhecida | 1 (slug + plano.md minimo) → 5 (kanban de 1-3 tasks) → 6 (QA reduzido). Pular 2-4 registrando "Pulada — porte pequeno" |
| **Medio** | 1 modulo, decisoes fechaveis numa sessao | Todas as 8, na profundidade padrao |
| **Grande/nebuloso** | Muitas frentes, decisoes do cliente sem forma, semanas | `/wayfinder` ANTES; esta skill retoma quando o caminho estiver claro |

**Valvula de seguranca (obrigatoria):** mesmo no porte pequeno, ANTES de implementar liste os passos atomicos. Se aparecerem **mais de 5 passos ou dependencias entre eles**, PARE e volte ao processo completo — o porte estava errado, nao o processo.

## Escopo declarado: a largura do que sera construido

Auto-sizing dimensiona a PROFUNDIDADE do processo. Esta secao dimensiona a LARGURA da entrega — quantas features entram. Vale em todos os portes, e morde mais forte nos grandes, onde pesquisa e interrogatorio produzem ideias mais rapido do que o cliente pediu.

**Escopo declarado** = o que o cliente pediu, registrado na Etapa 1 como 1 a 5 linhas numeradas (E-1, E-2, ...), cada uma com a fonte (ticket, e-mail, reuniao). E o **teto** da entrega, nao o piso.

**Origem obrigatoria.** Toda ideia que aparecer depois — na pesquisa, no interrogatorio, no PRD, no kanban — e uma de duas coisas:

- **Derivada**: implica diretamente numa linha do escopo declarado (sem ela, E-n nao funciona). Entra, citando `E-n`.
- **Extra**: tudo o mais, inclusive o que parece obviamente util. Vai para `## Fora de escopo / rejeitado` do plano.md com o motivo `sem pedido do cliente — propor depois`, e vira pergunta em `perguntas-cliente.md` se valer a pena oferecer. Extra so entra no escopo depois que o cliente pedir — dai ganha linha propria E-n com fonte.

**Toda feature e conversada e aprovada.** Nenhuma feature entra no escopo declarado por decisao da sessao. Ao identificar uma candidata (derivada ou extra), PARE e apresente ao usuario, uma a uma: *o que e, de qual linha E-n deriva ou por que e extra, custo estimado (fontes/tasks), e o que acontece se ficar de fora*. Espere o **sim explicito** dessa feature — silencio, "pode seguir" generico e aprovacao de uma feature anterior nao valem para a proxima. Aprovada, ela ganha linha E-n com fonte `aprovado por <usuario/cliente> em <data>` e entra no plano.md; recusada, desce para `## Fora de escopo / rejeitado` no mesmo momento. Vale tambem para feature que o usuario aprovou e depois cresceu: a parte nova e uma feature nova, com sua propria conversa.

**YAGNI nos suspeitos de sempre.** Estes nascem extras, nunca derivados: tela de manutencao/consulta que ninguem pediu, parametro MV para tornar configuravel algo com um unico valor conhecido, tabela de log/auditoria propria, tratamento generico para casos que o cliente nao descreveu, cadastro auxiliar "para facilitar depois", relatorio complementar. Implemente o caso que o cliente descreveu; o generico entra quando ele descrever o segundo caso.

**Passada de corte.** Antes de fechar o PRD (Etapa 4) e antes de fechar o kanban (Etapa 5), liste CADA requisito / CADA card com sua origem (`E-n` ou fonte do cliente). Item sem origem sai do documento e desce para `## Fora de escopo / rejeitado`. Registre no plano.md quantos itens sairam — passada que nunca corta nada geralmente e passada que nao foi feita.

## Estrutura de arquivos

### Todos os artefatos da customizacao ficam em `.claude/plans/<slug>/`

**Uma unica pasta por customizacao** — plano, pesquisa, decisoes, PRD, kanban, QA, pre-producao e perguntas-cliente vivem juntos. Nada vai para `docs/` do projeto: esses artefatos sao planejamento interno, nao acompanham o repositorio do cliente.

```
.claude/plans/brenner-controle-refugo-pcp-001323/
  plano.md            # Indice central — status de cada etapa
  research.md         # Pesquisa tecnica
  decisoes-cliente.md # Mapa de decisoes — versao para o cliente revisar
  prd.md              # Documento de requisitos (via /prd-protheus)
  kanban.md           # Fallback do kanban — so quando nao ha kanban provider na maquina (ver ETAPA-5-KANBAN.md)
  qa.md               # Plano de testes para execucao humana
  pre-producao.md     # Campos/parametros/indices a criar no Configurador (criado sob demanda)
  perguntas-cliente.md # Duvidas em aberto aguardando resposta do cliente (criado sob demanda)
  casos-e-regras.md   # Canone de regras de negocio RN/CB (criado quando a 1a regra com fonte aparecer)
  divergencias.md     # Diario de divergencias IA x realidade do ambiente (criado no 1o caso)
  fixes/              # Bug-specs de correcoes pos-kanban (criado no 1o bug)
```

`pre-producao.md` e `perguntas-cliente.md` sao criados **sob demanda** — quando a primeira necessidade aparecer (campo novo a criar, pergunta sem fonte do cliente). Nao precisa criar vazio.

### Convencao de slug

- **`<feature-slug>`**: `<cliente>-<descricao-curta>`. Exemplos:
  - `brenner-controle-refugo-pcp`
  - `smartech-api-integracao-wms`
  - `selbetti-relatorio-comissoes`
- **`<ticket>`**: numero do ticket (tspace/jira/e-mail) com zero-padding consistente, ex: `001323`.
- **Nome da pasta**:
  - Com ticket: `<feature-slug>-<ticket>` (ex: `brenner-controle-refugo-pcp-001323`)
  - Sem ticket: apenas `<feature-slug>`

---

## Etapa 1: Ideia

**Objetivo:** Entender o que sera construido.

Pergunte ao usuario:
- Qual a customizacao ou feature?
- Para qual cliente/projeto?
- Qual modulo Protheus envolvido?
- **Numero do ticket** (tspace/jira/e-mail) — se nao houver, registrar "sem ticket" e seguir
- Existe alguma referencia ou solicitacao documentada?

Com isso, escreva o **escopo declarado** (E-1..E-n, uma linha por coisa pedida, cada uma com fonte) na secao `## Escopo declarado` do plano.md e leia de volta ao usuario para ele confirmar linha a linha. O que voce achar que faz falta ali e proposta a conversar, nao linha a escrever.

**Escopo grande ou nebuloso demais?** Se as respostas revelarem um esforco que nao cabe numa sessao de planejamento — muitas frentes, decisoes que dependem do cliente ainda sem forma, semanas de trabalho — sugira ao usuario rodar `/wayfinder` primeiro (mapa de decisoes em `.claude/plans/<slug>/`, uma decisao por sessao) e retomar esta skill quando o caminho estiver claro.

Com as respostas, **defina o slug** (`<feature-slug>[-<ticket>]`) e crie a pasta `.claude/plans/<slug>/` com o `plano.md`. Os demais arquivos (`research.md`, `decisoes-cliente.md`, `prd.md`, `kanban.md`, `qa.md`, `pre-producao.md`, `perguntas-cliente.md`) sao adicionados nas etapas seguintes, conforme necessidade.

Ao criar o `plano.md`, leia `templates/plano.md` (nesta skill) e use-o na integra — inclusive a secao `## Fora de escopo / rejeitado` (uma linha por conceito descartado + motivo duravel + fonte; consultar antes de re-propor algo ao cliente).

**Docs com ciclo de vida (portes medio/grande):**
- Inicie um repo git PROPRIO em `.claude/` do projeto (`git -C .claude init`), separado do repo de entrega — docs internos nao vao ao remote do cliente. Commit `docs: <mudanca>` ao fim de cada sessao/lote: sem historico, corpo diverge de cabecalho sem rastro.
- Duravel x andaime: docs que acompanham o produto (catalogo de erros, padroes aprovados, manual da customizacao) vivem numa pasta de docs JUNTO dos fontes; `.claude/plans/` e andaime de desenvolvimento. Prever a promocao dos duraveis ao fim.
- Conflito entre documentos: vale o mais recente, e o conflito e REGISTRADO, nunca sobrescrito em silencio. Afirmacao de doc de referencia que divergir do ambiente real → registrar em `divergencias.md`.

Atualize a etapa e avance.

**Concluida quando:** pasta `.claude/plans/<slug>/` criada com `plano.md` preenchido conforme o template e usuario confirmou o slug.

---

## Etapa 2: Pesquisa

**Objetivo:** Levantar tudo que e necessario saber antes de implementar.

### Ordem obrigatoria: TDN primeiro, custom depois

A pesquisa segue ordem fixa — TDN do modulo padrao TOTVS **antes** de abrir qualquer fonte custom:

1. **Manual operacional do modulo** no TDN — ler a visao geral do fluxo padrao da rotina envolvida (ex: "Apontamento PCP Modelo 2 - MATA681", "Cadastro de Produtos - MATA010"). Entender o caminho oficial antes de qualquer coisa.
2. **Lista de parametros MV do modulo** — buscar TDN pela CATEGORIA, nao so pelo parametro obvio do bug. Procurar por label (ex: `parametros_sigapcp`, `parametros_sigaest`) ou query ampla ("parametros MV SIGAPCP", "MV PCP roteiro apontamento"). Parametros centrais (ex: `MV_PCPATOR`, `MV_REQAUT`) frequentemente ja resolvem o problema sem precisar de codigo custom.
3. **Lista de tabelas padrao** envolvidas e o papel de cada uma, uma linha cada (ex no PCP: SG2 = roteiro do produto, SHY = operacoes x OP, SH6 = movimento de producao, SH8 = recursos da OP).
4. **Caminho oficial do fluxo no padrao**, passo a passo, sem o custom no meio.
5. **Somente depois** mapear o custom do cliente — e enquadrar como "o que ele fez diferente do padrao", nao como ponto de partida.

**Por que e load-bearing:** muitas customizacoes Protheus existem porque o cliente nao sabia (ou nao ativou) um comportamento que o padrao ja oferece via parametro MV. Mergulhar no custom antes de verificar o padrao pode levar a propor PE/tabela nova/codigo extenso para algo que se resolve com `MV_X = T`. Em casos reais ja custou dias de investigacao em algo que era simples.

**Heuristica "duas tabelas paralelas = pergunta":** se aparecer no codebase uma tabela custom (`Z**`) que parece duplicar o papel de uma tabela padrao (ex: SZ2 paralela a SG2, SZ3 paralela a SHY), **parar e perguntar antes de seguir**: *"o padrao TOTVS nao cobre isso? por que o cliente duplicou?"*. Pode existir um parametro que ativa o comportamento padrao equivalente — ou a duplicacao tem motivo historico que muda o desenho da solucao.

**Pergunta padrao para mandar ao cliente cedo:** *"Lista de parametros MV do modulo e valores atuais (vs default). Quais foram modificados ao longo do tempo, e por que?"*. Pode ser extraida por SQL: `SELECT X6_VAR, X6_CONTEUD, X6_DEFAULT FROM SX6 WHERE X6_FIL = '<filial>' ORDER BY X6_VAR` — filtrar depois pelos prefixos do modulo.

### Checklist de ambiente (perguntar CEDO — resposta tardia ja forcou replanejamento inteiro)

- [ ] Da para testar o EFEITO FINAL no ambiente (faturar, emitir, calcular)? Se nao: qual o nivel de evidencia possivel, declarado desde ja?
- [ ] Existe base isolada para testes/TDD?
- [ ] O release/licenca do cliente suporta a UI planejada (PO-UI exige cloud/MPP — confirmar ANTES de prometer tela)?
- [ ] Integracao: o cliente aceita API ou so arquivo?
- [ ] Quem sobe/reinicia servidor de dev/TST?
- [ ] Massa de teste REAL do cliente disponivel? Catalogar CEDO (vira golden files) — massa sintetica inventada na hora do codigo e mentirosa.

### O que pesquisar

Use agentes e plugins (TDN, codebase exploration) para investigar:

| Topico | O que buscar |
|--------|-------------|
| **Rotinas padrao** | Quais rotinas padrao do Protheus estao envolvidas (MATA010, FINA040, etc.) |
| **Tabelas** | Tabelas padrao e custom (Z**) que serao lidas/gravadas, aliases, campos-chave |
| **Pontos de entrada** | PEs existentes nas rotinas envolvidas, parametros que recebem |
| **Parametros MV** | MV_* relevantes ao fluxo |
| **Funcoes do framework** | Funcoes/metodos nativos a utilizar (FWFormModel, MsExecAuto, etc.) |
| **Customizacoes existentes** | Codigo custom do cliente que ja existe para este fluxo |
| **Integracoes** | Modulos/sistemas externos que serao afetados |

### Como pesquisar

Segue a ordem da secao "Ordem obrigatoria" acima — TDN do modulo antes do codebase do cliente.

0. **CONTEXT.md e ADRs** — se existirem (raiz do projeto ou `.claude/plans/<slug>/`), leia antes: vocabulario do cliente e decisoes ja firmadas. Termo do cliente ambiguo ou novo durante a pesquisa → skill `domain-modeling`.
1. **TDN do modulo padrao** — use o plugin MCP do TDN (tdn_search/tdn_fetch) para o manual operacional, lista de parametros MV (por label/categoria, nao so por nome) e lista de tabelas. Esta etapa NAO e opcional.
2. **Codebase do cliente** — explore o diretorio do projeto para encontrar customizacoes existentes. **Apos** o mapeamento do padrao, nunca antes.
3. **TDN para funcoes/PEs especificos** — depois que o desenho da solucao comeca a tomar forma, validar funcoes do framework e PEs individuais.
4. **Web** — busque na web quando necessario para informacoes complementares.
5. **Agentes especializados** — use os agents de docs-reference e process-consultant quando necessario.

**Fallback de ferramentas:** se `tdn_search`/`tdn_fetch` (plugin claude-tdn) ou os agents docs-reference/process-consultant estiverem indisponiveis, use o MCP `advpl-tlpp-mcp-docs` ou pesquisa na TDN via curl (paginas TOTVS retornam 403 no WebFetch; curl com UA de navegador funciona).

**Antes de fixar um padrao/processo proprio** (ciclo de teste, padrao de codigo, padrao de tela): pesquisar o padrao OFICIAL primeiro — TOTVS/TDN para plataforma, docs da Anthropic para praticas com IA — e adaptar por decisao registrada, nao inventar do zero.

### Validacao Obrigatoria (nao pular)

Apos identificar funcoes e tabelas na pesquisa livre, execute antes de avancar:

**Modulo TOTVS — antes de qualquer outra validacao:**
1. `tdn_search` pela CATEGORIA de parametros do modulo (ex: "parametros SIGAPCP", "parametros MV SIGAEST"). Listar TODOS os parametros relevantes ao submodulo onde o bug acontece — nao so o obviamente relacionado.
2. Para cada parametro listado: verificar valor atual no ambiente do cliente (`SELECT X6_VAR, X6_CONTEUD FROM SX6 WHERE X6_VAR = 'MV_...'`). Registrar no `research.md` > "Parametros MV": parametro, valor atual, default, impacto.
3. `tdn_search` pelo manual operacional da rotina principal (ex: "MATA681 - Apontamento de Producao"). Registrar fluxo padrao no `research.md` > "Caminho oficial do fluxo no padrao".

**TDN — para cada funcao/metodo do framework identificado:**
1. `tdn_search` com apenas o nome da funcao (ex: "MsExecAuto", "FWRest")
2. Se encontrar resultado: `tdn_fetch` para obter parametros, retorno e observacoes
3. Registre no `research.md` > secao "Validacao TDN": nome, parametros, retorno, status
4. Se nao encontrar: registre como "sem documentacao TDN" e consulte as skills locais (`mvc-generator`, `data-dictionary-lookup`) ou o MCP `advpl-tlpp-mcp-docs`

**Dicionario — para cada tabela identificada:**
1. `dicionario_fetch` com o alias da tabela (ex: "SA1", "SC5") — se indisponivel, use o MCP `advpl-tlpp-mcp-docs` ou pesquisa na TDN via curl
2. Registre no `research.md` > secao "Dicionario de Dados": campos relevantes, tipo, tamanho, indices disponiveis

**Dicionario REAL do cliente — buscar customizacoes nas tabelas envolvidas (nao pular):**

O dicionario de referencia TOTVS (MCP) mostra o PADRAO — nao mostra campos custom do cliente nem tamanhos alterados (ex: A1_COD=8 em cliente onde o padrao e 6). Antes de fechar a pesquisa, pedir ao usuario que rode no ambiente do cliente (TST/PROD) e cole o resultado:

```sql
SELECT X3_ARQUIVO, X3_ORDEM, X3_CAMPO, X3_TIPO, X3_TAMANHO, X3_DECIMAL,
       X3_TITULO, X3_DESCRIC, X3_CONTEXT, X3_OBRIGAT, X3_F3, X3_VALID, X3_USADO
FROM SX3<EMP>
WHERE X3_ARQUIVO IN ('<TABELAS ENVOLVIDAS>')
  AND D_E_L_E_T_ = ' '
ORDER BY X3_ARQUIVO, X3_ORDEM
```

(SQL sempre ANSI — o banco do cliente varia entre projetos. Incluir tambem `SELECT INDICE, ORDEM, CHAVE FROM SIX<EMP> WHERE INDICE IN (...)` se a customizacao depende de chave/indice.)

Se o projeto tiver `.genericquery.json`, rode a consulta voce mesmo via skill `genericquery` em vez de pedir ao usuario.

Com o resultado, registrar no `research.md` secao "Dicionario REAL do cliente":
1. **Campos custom** (`?_Z*` ou sem prefixo Z mas ausentes do dicionario de referencia) de cada tabela envolvida — podem mudar o desenho (campo que a feature precisa pode ja existir).
2. **Tamanhos/tipos divergentes do padrao** — reforca o uso de `TamSX3` e afeta layout de arquivos/integracoes.
3. **Obrigatoriedade e X3_VALID reais** — o que o ambiente vai exigir/validar de fato (ex: campo obrigatorio no padrao pode nao ser no cliente, e vice-versa).
4. Cruzar com os nomes de campo citados pelo cliente no ticket/planilha — anotacao do cliente pode estar errada (campo inexistente ou trocado); divergencia vira pergunta em `perguntas-cliente.md`.

### Template do research.md

Ao criar o `research.md`, leia `templates/research.md` (nesta skill) e use-o na integra.

Apos preencher o research.md, atualize o `plano.md` e avance.

**Concluida quando:** `research.md` criado com as validacoes obrigatorias registradas (Parametros MV, Validacao TDN, Dicionario de Dados, Dicionario REAL do cliente) e `plano.md` atualizado.

---

## Etapa 3: Duvidas

**Objetivo:** Stress-test do plano antes de formalizar.

Invoque a skill `/interrogatorio-advpl` passando o contexto da pesquisa ja realizada. O interrogatorio vai questionar sobre:
- Modelo de dados, multi-filial, abordagem (MVC/tradicional/REST/Job)
- Integracoes entre modulos, PEs, concorrencia, performance
- Dicionario, seguranca, compatibilidade

As decisoes tomadas durante o interrogatorio devem ser **registradas no `plano.md`** em uma secao `## Decisoes`:

```markdown
## Decisoes (Etapa 3 - Duvidas)
- **Abordagem**: MVC com FWFormModel — justificativa: cadastro CRUD simples
- **Multi-filial**: Tabela exclusiva — cada filial tem seus proprios registros
- **Indice**: Criar SIX para ZXX com campos ZXX_FILIAL+ZXX_COD
- ...
```

O interrogatorio decide COMO construir o escopo declarado, nao QUANTO construir. Resposta que acrescenta feature nova (tela, tabela, parametro, rotina auxiliar) e candidata: conversar e aprovar antes de virar decisao, ou desce para `## Fora de escopo / rejeitado`.

**Regras de negocio com fonte do cliente** ganham ID e canone proprio: crie `casos-e-regras.md` (leia `templates/casos-e-regras.md` nesta skill) — RN-xx/CB-xx citados em fonte, kanban e QA; os demais docs citam o ID, nunca reescrevem o texto.

**Interrogatorio por artefato:** em portes medio/grande, artefatos duraveis que virarao gabarito (padroes de codigo, arquitetura, modelagem) merecem interrogatorio dedicado proprio, item a item com status de aprovacao — o artefato so vira gabarito citavel depois de sobreviver ao proprio interrogatorio.

### Mapa de decisoes para validacao com o cliente (`decisoes-cliente.md`)

Apos consolidar as decisoes no `plano.md`, gere `decisoes-cliente.md`
na mesma pasta. Este e o documento que o **responsavel tecnico envia
ao cliente** para revisar e bater item por item antes de fechar o
escopo. E diferente do `plano.md`:

| | `plano.md` (interno) | `decisoes-cliente.md` (cliente) |
|---|---|---|
| Publico | Equipe tecnica | Cliente (usuario-chave do negocio) |
| Linguagem | Tecnica: lock, transaction, alias | Negocio: regra, parametro, tabela, campo |
| Detalhe | Implementacao + razao tecnica | O que muda no comportamento + onde validar |
| Atualizacao | Continua (toda etapa do plano) | Versionado com changelog |

#### Quando criar e quando atualizar

- **Primeira versao**: imediatamente apos o interrogatorio (Etapa 3),
  com base nas decisoes consolidadas. Enviada ao cliente para revisao
  antes do PRD (Etapa 4).
- **Revisoes**: sempre que (a) o cliente responder uma pergunta em
  aberto, (b) uma decisao for revisada durante implementacao
  (ex: descoberta em TST), (c) escopo for ampliado/reduzido. **Toda
  mudanca substantiva entra no changelog do proprio arquivo** — nunca
  sobrescreva uma decisao antiga sem registrar.

#### Template e regras

Ao criar ou revisar o `decisoes-cliente.md`, leia `templates/decisoes-cliente.md` (nesta skill) e siga-o na integra — contem a estrutura do documento, temas tipicos por modulo, regras de linguagem (load-bearing) e formato/regras do changelog.

Atualize o `plano.md` e avance.

**Concluida quando:** decisoes do interrogatorio registradas na secao `## Decisoes` do `plano.md` e `decisoes-cliente.md` gerado (versao inicial com changelog) para envio ao cliente.

---

## Etapa 4: PRD

**Objetivo:** Formalizar requisitos em um documento-guia.

Invoque a skill `/prd-protheus` passando:
- A descricao da ideia (Etapa 1)
- A pesquisa realizada (Etapa 2)
- As decisoes tomadas (Etapa 3)

As decisoes ja estao em `plano.md`/`decisoes-cliente.md` — a `/prd-protheus` deve SINTETIZAR a partir delas, nao re-entrevistar o usuario. Salvar o resultado como `prd.md` na mesma pasta do plano.

**Passada de corte no PRD** (antes de fechar): liste cada requisito com a origem (`E-n` ou fonte do cliente). Requisito sem origem sai do prd.md e desce para `## Fora de escopo / rejeitado` do plano.md. Apresente a lista de cortes ao usuario — corte revertido so por aprovacao explicita dele, que vira linha E-n nova.

Atualize o `plano.md` e avance.

**Concluida quando:** `prd.md` salvo na pasta do plano, sintetizado a partir das decisoes existentes, **cada requisito citando sua origem (`E-n` ou fonte do cliente)**, passada de corte apresentada ao usuario e `plano.md` atualizado.

---

## Etapa 5: Kanban

**Objetivo:** Quebrar o PRD em tarefas atomicas e rastrear implementacao.

Leia `ETAPA-5-KANBAN.md` (nesta skill) e siga-o na integra: descoberta do **kanban provider** instalado na maquina (fallback `kanban.md` na pasta do plano), **modo de aprovacao** (perguntado ao usuario a cada sessao), conversa por comentarios no card com flags `comentado`/`pergunta`, estados de espera **TRABALHO HUMANO** e **AGUARDANDO TERCEIROS** (com cobranca datada), contrato do card, camadas e gates, fatiamento tracer-bullet, passada de corte, movimentacao durante a implementacao e execucao delegada por agentes.

Atualize o `plano.md` e avance.

**Concluida quando (criacao):** modo de aprovacao perguntado ao usuario nesta sessao, kanban criado no provider (ou no `kanban.md` de fallback) com tarefas atomicas cobrindo todo o PRD — nada alem dele —, cada uma com criterio de aceite e campo **Origem** preenchido, e provider/board/modo registrados na linha **Kanban** do `plano.md`. **Implementacao concluida quando:** todas as tasks em DONE.

---

## Etapa 6: QA

**Objetivo:** Criar plano de testes para execucao HUMANA.

### Quando sugerir execucao

Sugira a execucao do QA **somente quando TODOS os itens do kanban estiverem em DONE** — a feature precisa estar completa para ser testada como um todo.

### Template do qa.md

Ao criar o `qa.md`, leia `templates/qa.md` (nesta skill) e use-o na integra (testes funcionais, regressao, borda e resumo final).

**Passada regra → codigo:** se existe `casos-e-regras.md`, rode a varredura no sentido REGRA → codigo (para cada RN/CB: onde esta implementada e o comportamento bate?) — comentario convicto e defeito sao indistinguiveis na leitura do fonte; so o confronto fonte-do-cliente x comportamento pega regra contrariada. Instrucoes no proprio template.

**Concluida quando:** `qa.md` criado com cenarios funcionais, de regressao e de borda, e — apos execucao humana — resumo final preenchido com "Aprovado: Sim".

---

## Etapa 7: Limpeza pre-producao

**Objetivo:** Deixar o fonte limpo de referencias internas de planejamento antes de subir em producao.

> Os arquivos do plano (`.claude/plans/<slug>/...`) **permanecem intactos** — sao historico interno do desenvolvedor, nao vao para o repositorio do cliente nem para producao. A limpeza aqui age apenas nos **fontes** que vao para o RPO.

### Quando executar

**Somente apos QA aprovado** (Etapa 6 com "Aprovado: Sim"). Antes disso a feature ainda pode voltar para ajustes — manter as referencias ajuda na rastreabilidade durante desenvolvimento.

### Pre-requisitos

- [ ] QA aprovado pelo executor humano
- [ ] Todas as duvidas registradas em `.claude/plans/<slug>/perguntas-cliente.md` foram resolvidas (resposta do cliente registrada)
- [ ] Todos os campos/parametros listados em `.claude/plans/<slug>/pre-producao.md` foram criados manualmente no Configurador

### Checklist de limpeza

**1. Remover comentarios `TODO Pergunta N` dos fontes**

Para cada fonte alterado durante a implementacao, busque por padroes:

```
// TODO Pergunta <N> (.claude/plans/<slug>/perguntas-cliente.md)
// Ref: .claude/plans/<slug>/perguntas-cliente.md
ConOut("[ROTINA] - AVISO: ... aplicando fallback")  # quando ja confirmado pelo cliente
```

Acoes:
- Se a pergunta foi respondida e o **fallback virou regra definitiva**: remover o `TODO` e o `ConOut` de aviso, deixando apenas o codigo final com comentario `// Ref: <e-mail/ticket/data da resposta do cliente>`.
- Se a pergunta foi respondida e o **comportamento mudou**: ajustar o codigo conforme a resposta do cliente, remover TODO e aviso.
- Se ainda houver pergunta em aberto: **NAO avance para Etapa 8**. Volte ao cliente.

**2. Remover comentarios apontando para `.claude/plans/<slug>/pre-producao.md`**

Buscar nos fontes por:
```
// Ver .claude/plans/<slug>/pre-producao.md
// Pre-producao: criar campo ZXX_YYY no Configurador
```

Substituir/remover por comentario que faca sentido sozinho (ou remover se desnecessario).

**3. Validar com grep**

Antes de marcar etapa como concluida, rodar busca pelos fontes alterados confirmando que NAO existem mais ocorrencias de:
- `.claude/plans/<slug>/perguntas-cliente.md`
- `.claude/plans/<slug>/pre-producao.md`
- `docs/<slug>/perguntas-cliente.md` e `docs/<slug>/pre-producao.md` (caminhos antigos — podem aparecer em fontes legados que usavam o layout antigo)
- `TODO Pergunta`

### Registro no plano.md

Adicione secao:

```markdown
## Limpeza pre-producao (Etapa 7)
**Data:** [DATA]

- [x] Comentarios `TODO Pergunta N` removidos de: lista de fontes
- [x] Refs a `.claude/plans/<slug>/pre-producao.md` removidas de: lista de fontes
- [x] Todas as N perguntas em `.claude/plans/<slug>/perguntas-cliente.md` respondidas
- [x] Todos os N campos/parametros em `.claude/plans/<slug>/pre-producao.md` criados no Configurador
- [x] Grep validado: zero ocorrencias residuais nos fontes
```

Atualize o `plano.md` e avance.

**Concluida quando:** grep confirma zero ocorrencias residuais nos fontes e secao "Limpeza pre-producao (Etapa 7)" registrada no `plano.md` com todos os itens marcados.

---

## Etapa 8: Aplicar em producao

**Objetivo:** Subir a customizacao no ambiente de producao.

### Pre-requisitos

- [ ] Etapa 7 (Limpeza) concluida
- [ ] Fontes commitados no repositorio do cliente
- [ ] Janela de deploy combinada com o cliente
- [ ] Plano de rollback definido (versao anterior dos fontes identificada)

### Checklist de deploy

**1. Dicionario (se aplicavel)**

- [ ] Confirmar com o cliente que campos/parametros/indices ja foram criados no Configurador de PRODUCAO (nao apenas em homologacao)
- [ ] Backup do dicionario antes do deploy (export SX3/SX6/SIX/SX1 da empresa afetada)

**2. Compilacao**

- [ ] Compilar todos os fontes da feature no RPO de producao
- [ ] Validar que compilacao foi sem warning/erro
- [ ] Conferir que a versao compilada bate com o commit do repositorio

**3. Validacao pos-deploy**

- [ ] Smoke test rapido na producao (1-2 cenarios criticos do `qa.md`)
- [ ] Monitorar logs (`ConOut`, log de execucao automatica) por janela combinada com o cliente
- [ ] Comunicar usuario-chave do cliente que a feature esta no ar

**4. Rollback (se necessario)**

Se algo critico falhar:
- Recompilar versao anterior dos fontes
- Restaurar dicionario do backup (se houver alteracao reversivel)
- Comunicar cliente imediatamente

### Registro no plano.md

```markdown
## Deploy em producao (Etapa 8)
**Data:** [DATA]
**Janela:** [HORA INICIO - HORA FIM]
**Responsavel:** [NOME]

- [x] Dicionario validado em PRODUCAO
- [x] Fontes compilados no RPO de producao
- [x] Smoke test executado — passou
- [x] Cliente notificado

**Status final:** Em producao desde [DATA HORA]
**Observacoes:** ...
```

Marque a etapa como concluida e finalize o plano.

**Concluida quando:** secao "Deploy em producao (Etapa 8)" registrada no `plano.md` com smoke test passado e cliente notificado.

---

## Fluxo Completo

```
/planejar-advpl → retomada (plano existente? wayfinder-map?) → auto-sizing
  1 Ideia (slug + plano.md)          → 2 Pesquisa (research.md)
  3 Duvidas (interrogatorio → decisoes + decisoes-cliente.md [+ casos-e-regras.md])
  4 PRD (sintese → prd.md)           → 5 Kanban (provider → camadas/gates → implementar)
  6 QA (qa.md + passada regra→codigo) → 7 Limpeza (grep zero residual)
  8 Producao (dicionario PROD → RPO → smoke test → notificar cliente)
```

## Regras gerais

- **Uma etapa por vez** — nao pule etapas, cada uma alimenta a proxima (excecoes: pulo declarado pelo auto-sizing de porte pequeno, sempre registrado no plano.md, ou pedido do usuario)
- **Sempre atualize o plano.md** ao concluir cada etapa
- **Feature nova so entra conversada e aprovada** — em qualquer etapa, proponha e espere o sim; sem o sim, vai para `## Fora de escopo / rejeitado`
- **Peca confirmacao** do usuario antes de avancar para a proxima etapa
- **Se o usuario pedir para pular uma etapa**, registre no plano.md como "Pulada — motivo: [razao]"
- **Ao retomar**, leia TODOS os arquivos existentes do plano para recuperar contexto completo
