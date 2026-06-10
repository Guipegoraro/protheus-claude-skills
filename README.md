# Protheus Claude Skills

Skills customizadas para desenvolvimento ADVPL/TLPP no TOTVS Protheus, usadas com [Claude Code](https://claude.ai/claude-code).

## Skills

### Planejamento e processo

| Skill | Descricao |
|-------|-----------|
| `planejar-advpl` | Processo completo de planejamento de customizacao Protheus em 8 etapas — ideia, pesquisa, interrogatorio, PRD, kanban, QA, limpeza pre-producao e aplicacao |
| `prd-protheus` | Gera PRDs (Documentos de Requisitos) para customizacoes Protheus via entrevista conversacional |
| `interrogatorio-advpl` | Stress-test de planos de customizacao — questiona cada aspecto ate validar todas as decisoes |

### Dicionario de dados (Configurador)

| Skill | Descricao |
|-------|-----------|
| `protheus-configurador-dicionario` | Cria e audita entradas do dicionario via Configurador — tabelas (SX2), campos (SX3 + SXG), indices (SIX) e parametros (SX6). Cobre namespaces de cliente, atributos X_*, regras UPDDISTR e seguranca de migracao |
| `protheus-consulta-padrao` | Desenha, audita e amarra Consulta Padrao (F3 / SXB). Cobre os 4 tipos de consulta, os 9 XB_TIPO, vinculo via X3_F3 e invocacao programatica (ConPad1, FWLookUp) |

### Geracao de codigo

| Skill | Descricao |
|-------|-----------|
| `fwmsprinter-pdf` | Referencia para criacao de PDFs com FWMSPrinter — coordenadas, metodos, layout |

### Sessao e setup

| Skill | Descricao |
|-------|-----------|
| `claudesql-setup` | Configura a API ClaudeSQL no ambiente Protheus para queries read-only via Claude |
| `session-summary` | Gera resumo denso da sessao atual (decisoes, padroes, arquivos, pendencias) para reload apos `/clear`. Detecta `.claude/plans/<slug>/` e entra em modo referencial quando ha plano via `planejar-advpl` |
| `session-resume` | Recarrega o resumo gerado por `session-summary`, restaurando contexto apos `/clear` |

## Instalacao

1. Clone este repositorio em `~/.claude/skills/`:

```bash
git clone https://github.com/Guipegoraro/protheus-claude-skills.git ~/.claude/skills
```

2. As skills ficam disponiveis automaticamente no Claude Code.

## Uso

Invoque via slash command (`/<skill-name>`) ou mencione o tema na conversa — o Claude reconhece os trigger words da descricao e carrega a skill automaticamente.

Exemplos:

- `/planejar-advpl` — iniciar ou retomar planejamento de customizacao
- `/prd-protheus` — criar documento de requisitos
- `/interrogatorio-advpl` — validar plano de customizacao
- `/protheus-consulta-padrao` — desenhar uma F3 / SXB nova
- `/protheus-configurador-dicionario` — criar campo / tabela / indice / parametro
- `/fwmsprinter-pdf` — referencia para PDFs
- `/claudesql-setup` — instalar/configurar ClaudeSQL no ambiente
- `/session-summary [nome]` — salvar resumo da sessao
- `/session-resume [nome]` — restaurar resumo apos `/clear`

## Fluxo recomendado

1. **Planejamento** — `/planejar-advpl` estrutura a customizacao (aciona `prd-protheus` e `interrogatorio-advpl` nas etapas certas) e produz o pacote em `.claude/plans/<slug>/`.
2. **Dicionario** — `/protheus-configurador-dicionario` desenha tabelas / campos / indices / parametros novos e gera o checklist em `pre-producao.md`. Para F3 / consultas padrao, `/protheus-consulta-padrao`.
3. **Implementacao** — geracao de codigo (`/fwmsprinter-pdf` para PDFs) e consulta direta ao banco via `/claudesql-setup`.
4. **Sessoes longas** — `/session-summary` ao final; `/session-resume` para retomar apos `/clear`. O `session-summary` detecta automaticamente se ha plano em `.claude/plans/<slug>/` e referencia em vez de duplicar.

## Convencoes

- Todo artefato de uma customizacao vive em `.claude/plans/<slug>/` (plano, PRD, kanban, QA, pre-producao, perguntas-cliente). Nada vai para `docs/` do projeto do cliente.
- Slug: `<feature-slug>-<ticket>` quando houver ticket, apenas `<feature-slug>` caso contrario.
- Dicionario sempre via Configurador, nunca via fonte. As skills `protheus-configurador-dicionario` e `protheus-consulta-padrao` documentam tudo em `pre-producao.md` para o consultor aplicar no deploy.
