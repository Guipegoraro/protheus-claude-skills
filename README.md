# Protheus Claude Skills

Skills customizadas para desenvolvimento ADVPL/TLPP no TOTVS Protheus, usadas com [Claude Code](https://claude.ai/claude-code).

## Skills

| Skill | Descricao |
|-------|-----------|
| `planejar-advpl` | Processo completo de planejamento de customizacao Protheus em 6 etapas — ideia, pesquisa, interrogatorio, PRD, kanban e QA |
| `prd-protheus` | Gera PRDs (Documentos de Requisitos) para customizacoes Protheus via entrevista conversacional |
| `interrogatorio-advpl` | Stress-test de planos de customizacao — questiona cada aspecto ate validar todas as decisoes |
| `fwmsprinter-pdf` | Referencia para criacao de PDFs com FWMSPrinter — coordenadas, metodos, layout |
| `session-summary` | Gera resumo denso da sessao atual (decisoes, padroes, arquivos, pendencias) para reload apos `/clear` |
| `session-resume` | Recarrega o resumo gerado por `session-summary`, restaurando contexto apos `/clear` |

## Instalacao

1. Clone este repositorio em `~/.claude/skills/`:

```bash
git clone https://github.com/Guipegoraro/protheus-claude-skills.git ~/.claude/skills
```

2. As skills ficam disponiveis automaticamente no Claude Code.

## Uso

Invoque via slash command ou mencione o tema na conversa:

- `/planejar-advpl` — iniciar ou retomar planejamento de customizacao
- `/prd-protheus` — criar documento de requisitos
- `/interrogatorio-advpl` — validar plano de customizacao
- `/fwmsprinter-pdf` — referencia para PDFs
- `/session-summary [nome]` — salvar resumo da sessao atual
- `/session-resume [nome]` — restaurar resumo apos `/clear`

## Fluxo recomendado

1. `/planejar-advpl` para estruturar a customizacao (ele ja aciona `prd-protheus` e `interrogatorio-advpl` nas etapas certas)
2. Implementacao com apoio das skills de referencia (`fwmsprinter-pdf`, etc.)
3. `/session-summary` ao final de sessoes longas; `/session-resume` para retomar apos `/clear`
