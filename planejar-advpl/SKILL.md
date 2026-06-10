---
name: planejar-advpl
description: Use when starting a new Protheus customization or feature, or mentions "planejar", "planejar advpl", "nova feature", "nova customizacao", "planejar customizacao". Guides through 6 stages - idea, research, interrogation, PRD, kanban, and QA for ADVPL/TLPP development.
---

# Planejar ADVPL

Skill de processo para planejar e acompanhar o desenvolvimento de features/customizacoes Protheus, da ideia ao QA.

## Retomada

Ao ser invocada, SEMPRE verifique primeiro se existe um plano em andamento:

1. Liste `.claude/plans/` para ver planos existentes
2. Se o usuario mencionar uma feature existente, leia o `plano.md` correspondente
3. Retome da etapa atual indicada no `plano.md`
4. Se nao existir plano, inicie pela Etapa 1

## Estrutura de arquivos

### Todos os artefatos da customizacao ficam em `.claude/plans/<slug>/`

**Uma unica pasta por customizacao** — plano, pesquisa, decisoes, PRD, kanban, QA, pre-producao e perguntas-cliente vivem juntos. Nada vai para `docs/` do projeto: esses artefatos sao planejamento interno, nao acompanham o repositorio do cliente.

```
.claude/plans/brenner-controle-refugo-pcp-001323/
  plano.md            # Indice central — status de cada etapa
  research.md         # Pesquisa tecnica
  decisoes-cliente.md # Mapa de decisoes — versao para o cliente revisar
  prd.md              # Documento de requisitos (via /prd-protheus)
  kanban.md           # Tarefas de implementacao
  qa.md               # Plano de testes para execucao humana
  pre-producao.md     # Campos/parametros/indices a criar no Configurador (criado sob demanda)
  perguntas-cliente.md # Duvidas em aberto aguardando resposta do cliente (criado sob demanda)
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

Com as respostas, **defina o slug** (`<feature-slug>[-<ticket>]`) e crie a pasta `.claude/plans/<slug>/` com o `plano.md`. Os demais arquivos (`research.md`, `decisoes-cliente.md`, `prd.md`, `kanban.md`, `qa.md`, `pre-producao.md`, `perguntas-cliente.md`) sao adicionados nas etapas seguintes, conforme necessidade.

Template do `plano.md`:

```markdown
# Plano: [Nome da Feature]

| Campo | Valor |
|-------|-------|
| **Cliente** | [NOME] |
| **Modulo** | [MODULO] |
| **Projeto** | [PASTA DO PROJETO] |
| **Ticket** | [NUMERO ou "sem ticket"] |
| **Slug** | [feature-slug-ticket — usado em .claude/plans/] |
| **Criado** | [DATA] |
| **Etapa atual** | 1 - Ideia |

## Descricao
[Resumo do que sera construido, 2-3 frases]

## Etapas
- [x] 1. Ideia — definida
- [ ] 2. Pesquisa
- [ ] 3. Duvidas
- [ ] 4. PRD
- [ ] 5. Kanban
- [ ] 6. QA
- [ ] 7. Limpeza pre-producao
- [ ] 8. Aplicar em producao
```

Atualize a etapa e avance.

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

1. **TDN do modulo padrao** — use o plugin MCP do TDN (tdn_search/tdn_fetch) para o manual operacional, lista de parametros MV (por label/categoria, nao so por nome) e lista de tabelas. Esta etapa NAO e opcional.
2. **Codebase do cliente** — explore o diretorio do projeto para encontrar customizacoes existentes. **Apos** o mapeamento do padrao, nunca antes.
3. **TDN para funcoes/PEs especificos** — depois que o desenho da solucao comeca a tomar forma, validar funcoes do framework e PEs individuais.
4. **Web** — busque na web quando necessario para informacoes complementares.
5. **Agentes especializados** — use os agents de docs-reference e process-consultant quando necessario.

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
4. Se nao encontrar: registre como "sem documentacao TDN" e consulte as skills do protheus-toolkit

**Dicionario — para cada tabela identificada:**
1. `dicionario_fetch` com o alias da tabela (ex: "SA1", "SC5")
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

Com o resultado, registrar no `research.md` secao "Dicionario REAL do cliente":
1. **Campos custom** (`?_Z*` ou sem prefixo Z mas ausentes do dicionario de referencia) de cada tabela envolvida — podem mudar o desenho (campo que a feature precisa pode ja existir).
2. **Tamanhos/tipos divergentes do padrao** — reforca o uso de `TamSX3` e afeta layout de arquivos/integracoes.
3. **Obrigatoriedade e X3_VALID reais** — o que o ambiente vai exigir/validar de fato (ex: campo obrigatorio no padrao pode nao ser no cliente, e vice-versa).
4. Cruzar com os nomes de campo citados pelo cliente no ticket/planilha — anotacao do cliente pode estar errada (campo inexistente ou trocado); divergencia vira pergunta em `perguntas-cliente.md`.

### Template do research.md

```markdown
# Pesquisa: [Nome da Feature]

**Data:** [DATA]
**Cliente:** [NOME] | **Modulo:** [MODULO]

---

## Rotinas Padrao Envolvidas
| Rotina | Descricao | Relevancia |
|--------|-----------|-----------|
| MATA010 | Cadastro de Produtos | Sera consultada para... |

## Tabelas
| Alias | Descricao | Uso | Campos-chave |
|-------|-----------|-----|-------------|
| SA1 | Clientes | Leitura | A1_COD, A1_LOJA |
| ZXX | [Custom] | Gravacao | ZXX_COD |

## Pontos de Entrada
| PE | Rotina | Descricao | Relevante porque |
|----|--------|-----------|-----------------|
| MT010INC | MATA010 | Inclusao de produto | Podemos usar para... |

## Parametros MV
| Parametro | Descricao | Valor padrao | Impacto |
|-----------|-----------|-------------|---------|
| MV_EXEMPLO | Descricao | .T. | Afeta... |

## Funcoes do Framework
| Funcao/Metodo | Uso planejado |
|---------------|--------------|
| FWFormModel | Base do cadastro MVC |

## Validacao TDN
| Funcao/Metodo | Parametros | Retorno | Status TDN |
|---------------|------------|---------|------------|
| MsExecAuto | ... | Logico | Documentado |
| FWFormModel | ... | Objeto | Sem doc TDN — ref: skill protheus-mvc |

## Dicionario de Dados
### SA1 — Clientes
| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A1_COD | C | 6 | Codigo do cliente |
| A1_LOJA | C | 2 | Loja |

**Indices disponiveis:** A1_COD+A1_LOJA (unico), ...

## Customizacoes Existentes no Cliente
| Fonte | Descricao | Relacao com esta feature |
|-------|-----------|------------------------|
| BRNCUST01.prw | Customizacao de PCP | Sera modificado para... |

## Integracoes
| Sistema/Modulo | Tipo | Descricao |
|---------------|------|-----------|
| Fiscal (SIGAFIS) | Trigger | Geracao de nota ao... |

## Notas e Descobertas
- [Anotacoes livres sobre o que foi descoberto durante a pesquisa]
```

Apos preencher o research.md, atualize o `plano.md` e avance.

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

#### Estrutura recomendada

```text
COMPILADO DE DECISÕES - [NOME DA FEATURE]
Ticket: [referência externa - tspace/jira/e-mail]

================================================================
1. [TEMA - ex: MODELO DE DADOS]
================================================================

1.1 [Decisão direta em uma frase. Quando o cliente vai conferir
    no Configurador, cite parâmetro/tabela/campo com nome exato.]

1.2 [Quando a decisão tem motivo importante, inclua "Motivo: ..."
    em frase curta logo abaixo.]

================================================================
2. [TEMA - ex: CÁLCULO X]
================================================================

2.1 ...
2.2 ...

================================================================
N. PARÂMETROS NOVOS PARA CRIAR NO CONFIGURADOR
================================================================

NOME_PARAM   default "valor"
    Descrição curta

JÁ EXISTENTES - só validar default em PROD:
- PARAM_X  -> deve ser "valor esperado"

================================================================
*** PERGUNTAS EM ABERTO ***
================================================================

1) [Pergunta direta para o cliente, com contexto curto + qual
   comportamento está em vigor enquanto não responde.]

================================================================
CHANGELOG
================================================================

[YYYY-MM-DD] - Versão inicial enviada ao cliente.

[YYYY-MM-DD] - [Descrição da mudança em uma frase].
    Fonte: [e-mail Fulano / ticket 00011638 / ata reunião DD/MM].
    Item afetado: seção X.Y.
```

#### Temas tipicos por modulo

Use como ponto de partida, ajuste ao caso:

- **Financeiro / Faturamento**: modelo de dados, formula de calculo,
  regras especiais (cliente/natureza/tipo), parametros, como o
  numero/saldo e atualizado, integracoes.
- **Compras**: modelo de dados, regras de aprovacao, parametros de
  alcada, integracoes (portal/ERP externo), tela vs job.
- **Estoque/PCP**: estrutura de produto, regras de movimentacao,
  regras de bloqueio/liberacao, atualizacoes em massa.
- **Importacao (EIC)**: chaves de processo (HAWB customizado vs
  padrao), integracoes com despachantes, fluxo de aprovacao.

#### Regras de linguagem (load-bearing)

- **Participio passado impessoal** — mesma voz dos apontamentos:
  "Considerados apenas titulos baixados", "Excluidos titulos do
  tipo INV". Evitar primeira pessoa ("decidimos", "fizemos").
- **Citar nomes de cliente/processo** quando ja sao conhecidos do
  cliente: "clientes 42671051 e 52085074", "processo 59533".
- **Citar parametros** com codigo exato do SX6 (`ASC_ASC06A001`,
  `MV_PAR01`) — o cliente confere no Configurador.
- **Citar tabelas e campos custom** com prefixo Z** (SZN, ZN_VLRNUM)
  — sao reais e podem aparecer em telas/relatorios/queries.
- **NAO citar** nomes de funcoes ADVPL/TLPP, classes, namespaces,
  variaveis internas, design patterns ou decisoes de implementacao
  (lock-by-name, idempotencia, begin transaction, FWPreparedStatement,
  alias temporario, etc). Se nao agrega ao entendimento do cliente,
  fica de fora.
- **Acentuacao correta** — o documento e lido por humano, nao por
  AppServer. `cálculo`, `parâmetro`, `função`, `decisões`, etc.
- **Pendencias para o cliente** ficam no bloco final "PERGUNTAS EM
  ABERTO". Sempre inclua: pergunta, contexto curto, qual
  comportamento esta em vigor enquanto nao responde.

#### Changelog — formato e regras

O bloco CHANGELOG fica no fim do arquivo. Cada entrada:

1. **Data ISO** (`YYYY-MM-DD`)
2. **Descricao em uma frase** do que mudou.
3. **Fonte** (em linha indentada): de onde veio a mudanca —
   e-mail, ticket, ata de reuniao, nome da pessoa. **Nunca
   omitir** — sem fonte a mudanca nao tem rastreabilidade.
4. **Item afetado**: numero da secao + tema (ex: "secao 6.5
   cobertura de POs sem SW6").

Ordem cronologica: mais antigo no topo, mais novo no fim. **Nunca
reescreva entrada antiga** — se uma decisao foi reposta, registre
uma nova linha "decisao X revertida apos resposta do Fulano".

Quando uma pergunta em aberto for respondida pelo cliente:

1. Move o item da secao "PERGUNTAS EM ABERTO" para a secao tematica
   apropriada (vira decisao consolidada).
2. Registra no changelog: `[DATA] - Q1 respondida por Fulano,
   mantida soma direta. Fonte: e-mail 12/05. Item afetado: secao 2.1.`
3. Ajusta o fonte ADVPL se a resposta mudou comportamento.

Atualize o `plano.md` e avance.

---

## Etapa 4: PRD

**Objetivo:** Formalizar requisitos em um documento-guia.

Invoque a skill `/prd-protheus` passando:
- A descricao da ideia (Etapa 1)
- A pesquisa realizada (Etapa 2)
- As decisoes tomadas (Etapa 3)

O PRD gerado deve ser salvo como `prd.md` na pasta do plano.

Atualize o `plano.md` e avance.

---

## Etapa 5: Kanban

**Objetivo:** Quebrar o PRD em tarefas atomicas e rastrear implementacao.

### Criacao do kanban.md

Com base no PRD, crie tarefas atomicas — cada uma implementavel em uma sessao de trabalho.

```markdown
# Kanban: [Nome da Feature]

**Ultima atualizacao:** [DATA]

---

## TODO

### TASK-001: [Titulo descritivo]
- **Descricao**: O que fazer
- **Arquivos**: `path/to/file.prw`, `path/to/file2.tlpp`
- **Complexidade**: Baixa | Media | Alta
- **Dependencias**: Nenhuma | TASK-XXX
- **Criterio de aceite**: O que define "pronto"

### TASK-002: [Titulo descritivo]
...

---

## DOING

(vazio no inicio)

---

## DONE

(vazio no inicio)
```

### Durante a implementacao

Ao trabalhar em um item:
1. Mova de TODO para DOING
2. Ao concluir, mova para DONE e adicione:
   ```markdown
   ### TASK-001: [Titulo] ✓
   - **O que foi feito**: Resumo do que foi implementado
   - **Arquivos modificados**: Lista final dos arquivos tocados
   - **Observacoes**: Qualquer nota relevante
   ```
3. Atualize `**Ultima atualizacao**` no topo

### Regras do Kanban
- Maximo 2 itens em DOING simultaneamente
- Se uma tarefa crescer demais, quebre em sub-tarefas
- Se descobrir trabalho nao previsto, adicione como nova TASK em TODO

Atualize o `plano.md` e avance.

---

## Etapa 6: QA

**Objetivo:** Criar plano de testes para execucao HUMANA.

### Quando sugerir execucao

Sugira a execucao do QA **somente quando TODOS os itens do kanban estiverem em DONE** — a feature precisa estar completa para ser testada como um todo.

### Template do qa.md

```markdown
# QA: [Nome da Feature]

**Data de criacao:** [DATA]
**Executor:** [HUMANO]
**Status:** Pendente | Em execucao | Concluido

---

## Pre-requisitos
- [ ] Todos os fontes compilados sem erro
- [ ] Dicionario atualizado (SX3/SIX/SX1/SX5)
- [ ] Ambiente de teste configurado (filial, usuario)

---

## Testes Funcionais

### CT-001: [Cenario de teste]
- **Pre-condicoes**: O que precisa estar configurado
- **Passos**:
  1. Passo 1
  2. Passo 2
  3. Passo 3
- **Resultado esperado**: O que deve acontecer
- **Resultado**: [ ] Passou / [ ] Falhou
- **Observacoes**:

### CT-002: [Cenario de teste]
...

---

## Testes de Regressao

> O que NAO pode quebrar — funcionalidades existentes que a customizacao toca.

### RT-001: [Funcionalidade existente]
- **Rotina**: [Nome da rotina padrao]
- **Teste**: Verificar que [comportamento] continua funcionando
- **Resultado**: [ ] Passou / [ ] Falhou
- **Observacoes**:

---

## Testes de Borda

### BT-001: [Cenario limite]
- **Cenario**: [Ex: campo vazio, valor negativo, registro duplicado]
- **Resultado esperado**: [Mensagem de erro, bloqueio, etc.]
- **Resultado**: [ ] Passou / [ ] Falhou

---

## Resumo Final
| Tipo | Total | Passou | Falhou |
|------|-------|--------|--------|
| Funcionais | 0 | 0 | 0 |
| Regressao | 0 | 0 | 0 |
| Borda | 0 | 0 | 0 |

**Aprovado**: [ ] Sim / [ ] Nao
**Observacoes finais**:
```

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

---

## Fluxo Completo

```
/planejar-advpl
    │
    ├─ Plano existente? → Ler plano.md → Retomar etapa atual
    │
    ├─ Etapa 1: Ideia
    │   └─ Perguntar (incl. ticket) → Definir slug → Criar .claude/plans/<slug>/plano.md
    │
    ├─ Etapa 2: Pesquisa
    │   └─ Agentes + TDN + Codebase → research.md
    │
    ├─ Etapa 3: Duvidas
    │   ├─ /interrogatorio-advpl → Decisoes no plano.md
    │   └─ Gerar decisoes-cliente.md (mapa para o cliente revisar,
    │      com changelog no proprio arquivo)
    │
    ├─ Etapa 4: PRD
    │   └─ /prd-protheus → prd.md
    │
    ├─ Etapa 5: Kanban
    │   └─ Quebrar PRD → kanban.md → Implementar
    │
    ├─ Etapa 6: QA
    │   └─ qa.md → Sugerir execucao quando TODO kanban estiver em DONE
    │
    ├─ Etapa 7: Limpeza pre-producao
    │   └─ Remover refs a .claude/plans/<slug>/* dos fontes → grep zero residual (arquivos do plano permanecem)
    │
    └─ Etapa 8: Aplicar em producao
        └─ Validar dicionario em PROD → compilar RPO → smoke test → notificar cliente
```

## Regras gerais

- **Uma etapa por vez** — nao pule etapas, cada uma alimenta a proxima
- **Sempre atualize o plano.md** ao concluir cada etapa
- **Peca confirmacao** do usuario antes de avancar para a proxima etapa
- **Se o usuario pedir para pular uma etapa**, registre no plano.md como "Pulada — motivo: [razao]"
- **Ao retomar**, leia TODOS os arquivos existentes do plano para recuperar contexto completo
