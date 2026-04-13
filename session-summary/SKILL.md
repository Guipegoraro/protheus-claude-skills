---
name: session-summary
description: Gera resumo consolidado da sessao atual — decisoes, padroes, arquivos trabalhados, bugs resolvidos, pendencias. Salva em arquivo para reload apos /clear. Use ao final de sessoes produtivas ou quando o contexto ficar grande.
argument-hint: [nome-do-resumo]
disable-model-invocation: true
---

# Session Summary

Gera um resumo denso e especifico da sessao atual, otimizado para recarregar contexto apos `/clear`.

## Regras fundamentais

- **Seja especifico, nunca vago**: paths exatos, nomes de variaveis, argumentos de linha de comando. "Corrigido NullReference em ZCALFAT.prw:L45 inicializando aLocal como array vazio" >>> "Corrigido um bug".
- **Preserve o PORQUE**: toda decisao precisa da justificativa. "Escolhi G1_ZCALFAT na SG1 porque o campo padrao nao suporta formula customizada" >>> "Adicionei campo na SG1".
- **Filtre ruido**: NAO inclua tentativas que falharam, explorações abandonadas, perguntas intermediarias. So entra o que sobreviveu e e verdade agora.
- **Gotchas sao prioridade**: Edge case e gotchas devem ser registrados. Preserve-os explicitamente.
- **Formato Markdown puro**: sem JSON, sem YAML no corpo. Markdown tem 16% menos tokens e LLMs parsam nativamente.
- **Nao crie resumos genericos**: cada item deve ser exclusivo ao projeto sendo trabalhado. Se poderia aparecer em qualquer projeto, nao inclua.

## Onde salvar

O resumo vai em `.claude/session-resume.md` no diretorio do projeto atual (working directory).

Se `$ARGUMENTS` foi fornecido, use como nome: `.claude/session-resume-$ARGUMENTS.md`

## Processo

### Passo 1: Coletar contexto

Analise toda a conversa e extraia informacoes nas 7 categorias abaixo. Use tambem:

- `git diff` e `git log --oneline -20` para confirmar o que realmente mudou
- Leitura dos arquivos trabalhados para capturar estado atual real (nao confie so na memoria da conversa)

### Passo 2: Gerar o resumo

Use exatamente este template:

```markdown
# Session Resume: [nome descritivo do trabalho]

Data: [YYYY-MM-DD]
Projeto: [nome do projeto/repo]
Working Directory: [path]

## 1. Objetivo

[O que esta sendo construido/resolvido e por que]

## 2. Decisoes de Design

| Decisao | Justificativa |
|---------|---------------|
| [o que foi escolhido] | [por que essa escolha e nao outra] |

## 3. Padroes Estabelecidos

- **[padrao]**: [regra concreta]. _Motivo: [por que]_

## 4. Arquivos Trabalhados

| Arquivo | Estado | O que faz / mudou |
|---------|--------|-------------------|
| [path completo] | [criado/modificado/removido] | [descricao concisa] |

## 5. Dicionario de Dados

[Campos, tabelas, configuracoes criadas ou modificadas. Se nao aplicavel, omita a secao]

| Tabela | Campo | Tipo | Descricao |
|--------|-------|------|-----------|

## 6. Problemas Resolvidos

- **[problema]**: Causa raiz: [causa]. Fix: [o que foi feito, com path:linha]

## 7. Gotchas e Aprendizados

- [coisas nao obvias que seriam faceis de esquecer e causar retrabalho]

## 8. Pendencias

- [ ] [tarefa concreta com path/arquivo se aplicavel]
- [ ] [proxima tarefa]

## 9. Contexto Historico

[Se ja existia um resumo anterior, incorpore os pontos-chave aqui para nao perder contexto acumulado. Se e o primeiro resumo, omita esta secao]
```

### Passo 3: Verificar contexto historico

Antes de salvar, verifique se ja existe `.claude/session-resume.md` (ou variante com nome).
Se existir, leia-o e incorpore os pontos relevantes na secao "Contexto Historico" do novo resumo.
NAO descarte resumos anteriores — acumule contexto.

### Passo 4: Mostrar preview

Mostre o resumo completo ao usuario e pergunte:

> **Resumo gerado. Revise e me diga:**
> 1. **Aprovar** — salvo e voce roda `/clear` seguido de `/session-resume`
> 2. **Editar** — me diga o que ajustar
> 3. **Cancelar** — descarto o resumo

### Passo 5: Salvar (apos aprovacao)

1. Salve o arquivo em `.claude/session-resume.md` (ou `.claude/session-resume-$ARGUMENTS.md`)
2. Confirme o salvamento e instrua:

> **Resumo salvo em `.claude/session-resume.md`**
> Agora rode:
> 1. `/clear`
> 2. `/session-resume`
