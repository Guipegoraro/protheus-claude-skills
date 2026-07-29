# Protheus Claude Skills

Skills customizadas para desenvolvimento TOTVS Protheus — ADVPL, TLPP, PO-UI e SQL — usadas com [Claude Code](https://claude.ai/claude-code).
aviso: nem todas as skills aqui listadas foram desenvolvidas por mim, aqui é basicamente um espelho da minha pasta de skills. Algumas das notáveis que desenvolvi é "Planejar ADPVPL" e as de configurador.
## Instalacao

1. Clone este repositorio em `~/.claude/skills/`:

```bash
git clone https://github.com/Guipegoraro/protheus-claude-skills.git ~/.claude/skills
```

2. As skills ficam disponiveis automaticamente no Claude Code (todas as sessoes, qualquer projeto). Para uso em um unico projeto, copie as pastas desejadas para `.claude/skills/` do repositorio do projeto.

## Uso

Invoque via slash command (`/<skill-name>`) ou mencione o tema na conversa — o Claude reconhece os trigger words da descricao e carrega a skill automaticamente.

## Skills

### Planejamento e processo

| Skill | Descricao |
|-------|-----------|
| `planejar-advpl` | Processo completo de planejamento de customizacao Protheus em 8 etapas — ideia, pesquisa, interrogatorio, PRD, kanban, QA, limpeza pre-producao e aplicacao |
| `prd-protheus` | Gera PRDs (Documentos de Requisitos) para customizacoes Protheus via entrevista conversacional |
| `interrogatorio-advpl` | Stress-test de planos de customizacao — questiona cada aspecto ate validar todas as decisoes |

### PO-UI (frontend Angular + backend Protheus)

| Skill | Descricao |
|-------|-----------|
| `po-ui-app` | Apps Angular com PO-UI, embarcados no Protheus (FwCallApp / protheus-lib-core) ou standalone via REST — contrato de API, componentes, templates dinamicos, autenticacao OAuth2, empacotamento `.app` |
| `protheus-api-poui` | APIs REST no Protheus (TLPP annotations, WSRESTFUL, FWAdapterBaseV2, FWRestModel) no padrao TOTVS/TTALK consumido pelo PO-UI, incluindo configuracao do appserver.ini (REST, CORS, OAuth2, MPP) |

### Geracao de codigo ADVPL/TLPP

| Skill | Descricao |
|-------|-----------|
| `mvc-generator` | Telas MVC (ModelDef/ViewDef/MenuDef/BrowseDef), Modelo 1 e Modelo 3, com validacoes, gatilhos e pontos de entrada |
| `entry-point-designer` | Design e documentacao de Pontos de Entrada (PARAMIXB, retornos, assinatura User Function) |
| `tlpp-rest-endpoint-generator` | Endpoints REST TLPP com annotations (@Get/@Post/...) e objeto oRest no padrao TTALK |
| `fwrest-client-generator` | Codigo AdvPL/TLPP que CONSOME APIs REST externas com FWRest (verbos, autenticacao, tratamento de erro) |
| `fwmsprinter-pdf` | Referencia para criacao de PDFs com FWMSPrinter — coordenadas, metodos, layout |
| `refazer-relatorio-classico` | Refaz relatorio classico TOTVS descontinuado (FINRxxx, MATRxxx...) como copia customizada que compila sem chave de compilacao |

### Dicionario de dados (Configurador)

| Skill | Descricao |
|-------|-----------|
| `protheus-configurador-dicionario` | Cria e audita entradas do dicionario via Configurador — tabelas (SX2), campos (SX3 + SXG), indices (SIX) e parametros (SX6). Cobre namespaces de cliente, atributos X_*, regras UPDDISTR e seguranca de migracao |
| `protheus-consulta-padrao` | Desenha, audita e amarra Consulta Padrao (F3 / SXB). Cobre os 4 tipos de consulta, os 9 XB_TIPO, vinculo via X3_F3 e invocacao programatica (ConPad1, FWLookUp) |
| `data-dictionary-lookup` | Consulta ao dicionario Protheus — SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB, SXG |

### SQL

| Skill | Descricao |
|-------|-----------|
| `query-builder` | Queries seguras e otimizadas para tabelas Protheus (D_E_L_E_T_, filial, FWExecStatement vs Workarea) |
| `sql-optimization` | Tuning de queries, estrategia de indices e analise de plano de execucao (PostgreSQL, SQL Server, Oracle) |
| `sql-code-review` | Review de SQL — seguranca (injection), qualidade e anti-padroes |

### Qualidade

| Skill | Descricao |
|-------|-----------|
| `code-review` | Code review AdvPL/TLPP — regras SonarQube, Protheus.doc, seguranca, performance, clean code |

### Sessao e setup

| Skill | Descricao |
|-------|-----------|
| `claudesql-setup` | Configura a API ClaudeSQL no ambiente Protheus para queries read-only via Claude |
| `session-summary` | Gera resumo denso da sessao atual (decisoes, padroes, arquivos, pendencias) para reload apos `/clear`. Detecta `.claude/plans/<slug>/` e entra em modo referencial quando ha plano via `planejar-advpl` |
| `session-resume` | Recarrega o resumo gerado por `session-summary`, restaurando contexto apos `/clear` |
| `apontamento-gerar` | Gera apontamento de trabalho para o cliente |

## MCPs recomendados

Algumas skills usam servidores MCP como fonte viva de documentacao:

```bash
claude mcp add po-ui --scope user -- cmd /c npx -y @po-ui/mcp
claude mcp add angular --scope user -- cmd /c npx -y @angular/cli mcp
claude mcp add chrome-devtools --scope user -- cmd /c npx -y chrome-devtools-mcp@latest
```

(Em Linux/macOS, remova o `cmd /c`. Se usa Chromium em vez de Chrome, adicione `--executablePath <caminho do chrome.exe do Chromium>` ao chrome-devtools.)

As skills de AdvPL/TLPP tambem aproveitam, quando disponiveis, um MCP de documentacao TOTVS (`advpl-tlpp-mcp-docs`) e um MCP de filesystem com suporte a CP1252 (`file-tools`) — fontes AdvPL/TLPP sao CP1252 e nao devem ser lidos/gravados como UTF-8.

## Fluxo recomendado

1. **Planejamento** — `/planejar-advpl` estrutura a customizacao (aciona `prd-protheus` e `interrogatorio-advpl` nas etapas certas) e produz o pacote em `.claude/plans/<slug>/`.
2. **Dicionario** — `/protheus-configurador-dicionario` desenha tabelas / campos / indices / parametros novos e gera o checklist em `pre-producao.md`. Para F3 / consultas padrao, `/protheus-consulta-padrao`.
3. **Implementacao** — MVC (`/mvc-generator`), REST (`/tlpp-rest-endpoint-generator`, `/protheus-api-poui`), frontend (`/po-ui-app`), PDFs (`/fwmsprinter-pdf`), integracoes (`/fwrest-client-generator`) e consulta direta ao banco via `/claudesql-setup` + `/query-builder`.
4. **Qualidade** — `/code-review` e `/sql-code-review` antes de aplicar.
5. **Sessoes longas** — `/session-summary` ao final; `/session-resume` para retomar apos `/clear`.

## Convencoes

- Todo artefato de uma customizacao vive em `.claude/plans/<slug>/` (plano, PRD, kanban, QA, pre-producao, perguntas-cliente). Nada vai para `docs/` do projeto do cliente.
- Slug: `<feature-slug>-<ticket>` quando houver ticket, apenas `<feature-slug>` caso contrario.
- Dicionario sempre via Configurador, nunca via fonte. As skills `protheus-configurador-dicionario` e `protheus-consulta-padrao` documentam tudo em `pre-producao.md` para o consultor aplicar no deploy.
- Outputs de desenvolvimento sempre em PT-BR (comentarios, commits, textos de UI); identificadores em ingles.
- Contrato REST PO-UI/TOTVS tem fonte unica em `po-ui-app/references/api-contract.md` — a skill de backend aponta para ele.
