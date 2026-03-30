# Protheus Claude Skills

Skills customizadas para desenvolvimento ADVPL/TLPP no TOTVS Protheus, usadas com [Claude Code](https://claude.ai/claude-code).

## Skills

| Skill | Descricao |
|-------|-----------|
| `prd-protheus` | Gera PRDs (Documentos de Requisitos) para customizacoes Protheus via entrevista conversacional |
| `interrogatorio-advpl` | Stress-test de planos de customizacao — questiona cada aspecto ate validar todas as decisoes |
| `fwmsprinter-pdf` | Referencia para criacao de PDFs com FWMSPrinter — coordenadas, metodos, layout |

## Instalacao

1. Clone este repositorio em `~/.claude/skills/`:

```bash
git clone https://github.com/Guipegoraro/protheus-claude-skills.git ~/.claude/skills
```

2. As skills ficam disponiveis automaticamente no Claude Code.

## Uso

Invoque via slash command ou mencione o tema na conversa:

- `/prd-protheus` — criar documento de requisitos
- `/interrogatorio-advpl` — validar plano de customizacao
- `/fwmsprinter-pdf` — referencia para PDFs
