---
name: session-summary
description: Gera resumo consolidado da sessao atual — decisoes, padroes, arquivos trabalhados, bugs resolvidos, pendencias. Salva em arquivo para reload apos /clear. Quando o projeto ja tem plano em .claude/plans/<slug>/ (via planejar-advpl), referencia esses artefatos em vez de duplicar. Use ao final de sessoes produtivas ou quando o contexto ficar grande.
argument-hint: [nome-do-resumo]
disable-model-invocation: true
---

# Session Summary

Gera um resumo denso e especifico da sessao atual, otimizado para recarregar contexto apos `/clear`.

## Regras fundamentais

- **Seja especifico, nunca vago**: paths exatos, nomes de variaveis, argumentos de linha de comando. "Corrigido NullReference em ZCALFAT.prw:L45 inicializando aLocal como array vazio" >>> "Corrigido um bug".
- **Preserve o PORQUE**: toda decisao precisa da justificativa. "Escolhi G1_ZCALFAT na SG1 porque o campo padrao nao suporta formula customizada" >>> "Adicionei campo na SG1".
- **Filtre ruido**: NAO inclua tentativas que falharam, exploracoes abandonadas, perguntas intermediarias. So entra o que sobreviveu e e verdade agora.
- **Gotchas sao prioridade**: edge cases e gotchas devem ser registrados. Preserve-os explicitamente.
- **Formato Markdown puro**: sem JSON, sem YAML no corpo. Markdown tem 16% menos tokens e LLMs parsam nativamente.
- **Nao crie resumos genericos**: cada item deve ser exclusivo ao projeto sendo trabalhado. Se poderia aparecer em qualquer projeto, nao inclua.
- **NAO duplique o que ja esta em `.claude/plans/<slug>/`** — quando ha plano via `planejar-advpl`, o resumo referencia os artefatos por path. Veja o **Passo 0** abaixo.

## Onde salvar

O resumo vai em `.claude/session-resume.md` no diretorio do projeto atual (working directory).

Se `$ARGUMENTS` foi fornecido, use como nome: `.claude/session-resume-$ARGUMENTS.md`

## Processo

### Passo 0: Detectar plano existente (`planejar-advpl`)

Antes de coletar qualquer coisa, verifique se existe um plano da skill `planejar-advpl` para esta customizacao:

1. Liste `.claude/plans/` no diretorio do projeto.
2. Se houver pasta(s), identifique o slug ativo — normalmente o que foi mencionado na conversa, ou o mais recentemente modificado.
3. Liste os artefatos presentes em `.claude/plans/<slug>/`:
   - `plano.md` — indice central e status de etapas
   - `research.md` — pesquisa tecnica
   - `prd.md` — requisitos do projeto
   - `kanban.md` — tarefas de implementacao
   - `qa.md` — plano de testes
   - `decisoes-cliente.md` — decisoes que aguardam revisao do cliente
   - `pre-producao.md` — campos/tabelas/parametros/consultas a aplicar no Configurador
   - `perguntas-cliente.md` — duvidas abertas

**Se existe plano**, o resumo entra em **modo referencial**: cada secao numerada do template aponta para o artefato canonico em vez de copiar o conteudo. O resumo so detalha o que e:

- **Novo desde o plano**: descobertas durante a implementacao que ainda nao viraram doc.
- **Divergente do plano**: pontos onde o plano mudou e o doc canonico ainda nao foi atualizado (marcar como pendencia para atualizar).
- **Especifico da sessao**: codigo escrito, bugs reais encontrados, gotchas que emergiram da implementacao.

**Se nao existe plano**, o resumo entra em **modo standalone** — funciona como antes, capturando tudo.

Registre o modo escolhido no topo do resumo (ver template).

### Passo 1: Coletar contexto

Analise toda a conversa e extraia informacoes nas categorias abaixo. Use tambem:

- `git diff` e `git log --oneline -20` para confirmar o que realmente mudou.
- Leitura dos arquivos trabalhados para capturar estado atual real (nao confie so na memoria da conversa).
- Leitura dos artefatos de `.claude/plans/<slug>/` (modo referencial) para evitar copiar conteudo ja documentado.

### Passo 2: Gerar o resumo

Use exatamente este template:

```markdown
# Session Resume: [nome descritivo do trabalho]

Data: [YYYY-MM-DD]
Projeto: [nome do projeto/repo]
Working Directory: [path]
Modo: [referencial (plano em .claude/plans/<slug>/) | standalone]
Plano: [.claude/plans/<slug>/ — apenas se modo referencial]

## 1. Objetivo

**Modo referencial**: Ver `.claude/plans/<slug>/plano.md` (Visao geral) e `.claude/plans/<slug>/prd.md` (Escopo).
[Adicione apenas o que mudou desde o plano, ou um delta de uma frase para ancorar.]

**Modo standalone**: [O que esta sendo construido/resolvido e por que]

## 2. Decisoes de Design

**Modo referencial**: Decisoes ja documentadas vivem em `.claude/plans/<slug>/prd.md` e `.claude/plans/<slug>/decisoes-cliente.md`. Liste aqui SOMENTE decisoes novas desta sessao.

| Decisao | Justificativa | Status |
|---------|---------------|--------|
| [o que foi escolhido nesta sessao] | [por que] | [nova / divergente do plano — referencia o item original] |

## 3. Padroes Estabelecidos

**Modo referencial**: Padroes ja registrados estao em `.claude/plans/<slug>/plano.md` ou no PRD. Liste aqui SOMENTE padroes novos emergentes da implementacao.

- **[padrao novo]**: [regra concreta]. _Motivo: [por que]_

## 4. Arquivos Trabalhados

[Sempre detalhe — o codigo nao esta no plano.]

| Arquivo | Estado | O que faz / mudou |
|---------|--------|-------------------|
| [path completo] | [criado/modificado/removido] | [descricao concisa] |

## 5. Dicionario de Dados

**Modo referencial**: campos/tabelas/parametros/consultas planejados vivem em `.claude/plans/<slug>/pre-producao.md`. Liste aqui SOMENTE entradas novas ou alteradas nesta sessao que ainda nao chegaram no pre-producao.

| Tabela | Campo | Tipo | Descricao | Status |
|--------|-------|------|-----------|--------|
| [tabela] | [campo] | [tipo] | [descricao] | [pendente em pre-producao.md / divergente / nova] |

## 6. Problemas Resolvidos

[Sempre detalhe — bugs reais nao estao no plano.]

- **[problema]**: Causa raiz: [causa]. Fix: [o que foi feito, com path:linha]

## 7. Gotchas e Aprendizados

**Modo referencial**: gotchas conhecidos no inicio vivem no PRD (Riscos) ou plano. Liste aqui SOMENTE gotchas que emergiram durante a implementacao.

- [coisas nao obvias que seriam faceis de esquecer e causar retrabalho]

## 8. Pendencias

**Modo referencial**: tarefas planejadas estao em `.claude/plans/<slug>/kanban.md`. Liste aqui:
- Itens do kanban que foram concluidos nesta sessao (com checkbox marcado para mover depois).
- Tarefas novas que emergiram e ainda nao estao no kanban.
- Atualizacoes pendentes nos docs canonicos (ex: "atualizar PRD com decisao X tomada nesta sessao").

- [ ] [tarefa concreta com path/arquivo se aplicavel]
- [ ] Atualizar `.claude/plans/<slug>/<doc>.md` com [o que]

## 9. Contexto Historico

[Se ja existia um resumo anterior, incorpore os pontos-chave aqui. Se e o primeiro resumo, omita.]
```

### Passo 3: Verificar contexto historico

Antes de salvar, verifique se ja existe `.claude/session-resume.md` (ou variante com nome).
Se existir, leia-o e incorpore os pontos relevantes na secao "Contexto Historico" do novo resumo.
NAO descarte resumos anteriores — acumule contexto.

### Passo 4: Mostrar preview

Mostre o resumo completo ao usuario e pergunte:

> **Resumo gerado** (modo: [referencial / standalone]). Revise e me diga:
> 1. **Aprovar** — salvo e voce roda `/clear` seguido de `/session-resume`
> 2. **Editar** — me diga o que ajustar
> 3. **Cancelar** — descarto o resumo

### Passo 5: Salvar (apos aprovacao)

1. Salve o arquivo em `.claude/session-resume.md` (ou `.claude/session-resume-$ARGUMENTS.md`)
2. Se houve pendencias do tipo "atualizar doc canonico" (secao 8), avise:

> Atencao: existem [N] pendencias de atualizacao de docs canonicos em `.claude/plans/<slug>/`. Aplique-as antes de outra sessao alterar o plano.

3. Confirme o salvamento e instrua:

> **Resumo salvo em `.claude/session-resume.md`**
> Agora rode:
> 1. `/clear`
> 2. `/session-resume`
