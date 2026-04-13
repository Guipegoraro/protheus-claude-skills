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

Todos os artefatos ficam em `.claude/plans/<client>-<feature-slug>/`:

```
.claude/plans/brenner-controle-refugo-pcp/
  plano.md        # Indice central — status de cada etapa
  research.md     # Pesquisa tecnica
  prd.md          # Documento de requisitos (via /prd-protheus)
  kanban.md       # Tarefas de implementacao
  qa.md           # Plano de testes para execucao humana
```

O `<feature-slug>` segue o padrao: `<cliente>-<descricao-curta>`. Exemplos:
- `brenner-controle-refugo-pcp`
- `smartech-api-integracao-wms`
- `selbetti-relatorio-comissoes`

---

## Etapa 1: Ideia

**Objetivo:** Entender o que sera construido.

Pergunte ao usuario:
- Qual a customizacao ou feature?
- Para qual cliente/projeto?
- Qual modulo Protheus envolvido?
- Existe alguma referencia ou solicitacao documentada?

Com as respostas, crie a pasta e o arquivo `plano.md`:

```markdown
# Plano: [Nome da Feature]

| Campo | Valor |
|-------|-------|
| **Cliente** | [NOME] |
| **Modulo** | [MODULO] |
| **Projeto** | [PASTA DO PROJETO] |
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
```

Atualize a etapa e avance.

---

## Etapa 2: Pesquisa

**Objetivo:** Levantar tudo que e necessario saber antes de implementar.

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

1. **Codebase do cliente** — explore o diretorio do projeto para encontrar customizacoes existentes
2. **TDN** — use o plugin MCP do TDN (tdn_search/tdn_fetch) para documentacao de funcoes e rotinas
3. **Web** — busque na web quando necessario para informacoes complementares
4. **Agentes especializados** — use os agents de docs-reference e process-consultant quando necessario

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

## Fluxo Completo

```
/planejar-advpl
    │
    ├─ Plano existente? → Ler plano.md → Retomar etapa atual
    │
    ├─ Etapa 1: Ideia
    │   └─ Perguntar → Criar pasta + plano.md
    │
    ├─ Etapa 2: Pesquisa
    │   └─ Agentes + TDN + Codebase → research.md
    │
    ├─ Etapa 3: Duvidas
    │   └─ /interrogatorio-advpl → Decisoes no plano.md
    │
    ├─ Etapa 4: PRD
    │   └─ /prd-protheus → prd.md
    │
    ├─ Etapa 5: Kanban
    │   └─ Quebrar PRD → kanban.md → Implementar
    │
    └─ Etapa 6: QA
        └─ qa.md → Sugerir execucao quando TODO kanban estiver em DONE
```

## Regras gerais

- **Uma etapa por vez** — nao pule etapas, cada uma alimenta a proxima
- **Sempre atualize o plano.md** ao concluir cada etapa
- **Peca confirmacao** do usuario antes de avancar para a proxima etapa
- **Se o usuario pedir para pular uma etapa**, registre no plano.md como "Pulada — motivo: [razao]"
- **Ao retomar**, leia TODOS os arquivos existentes do plano para recuperar contexto completo
