---
name: prd-protheus
description: Use quando o usuario quiser criar um PRD para customizacao Protheus, ou mencionar "PRD", "documento de requisitos", "requisitos do projeto", "escopo da customizacao", "levantamento de requisitos", "especificacao", "nova feature protheus".
---

# PRD para Customizacoes Protheus

Gere um Documento de Requisitos de Produto (PRD) para customizacoes ADVPL/TLPP no ERP TOTVS Protheus atraves de entrevista conversacional com o usuario.

Funciona para desenvolvimento novo e melhorias em codigo existente.

TODO o output deve ser em Portugues Brasileiro.

NUNCA crie GitHub Issues. O PRD e sempre exibido como texto na conversa.

## Processo

### Passo 0: Verificar se veio do planejar-advpl (modo sintese)

Se esta skill foi invocada a partir do **planejar-advpl** (existe `.claude/plans/<slug>/plano.md` da customizacao em questao), **NAO re-entreviste o usuario**:

1. Leia `plano.md` e `decisoes-cliente.md` da pasta `.claude/plans/<slug>/`.
2. SINTETIZE o PRD a partir das decisoes ja registradas, usando o template abaixo.
3. Pergunte APENAS o que estiver genuinamente em aberto (lacunas reais, nao confirmacao do que ja foi decidido).
4. Salve o resultado como `prd.md` na mesma pasta `.claude/plans/<slug>/`.

O modo entrevista completo (Passos 1 a 7) continua valendo para uso standalone da skill.

### Passo 1: Detectar contexto do projeto

Verifique se existem fontes ADVPL/TLPP no diretorio atual:

```
Glob: **/*.prw
Glob: **/*.tlpp
```

Leia tambem o CLAUDE.md e/ou README.md do projeto se existirem — eles contem convencoes, prefixos, tabelas custom e arquitetura.

Se encontrar arquivos de codigo, pergunte ao usuario:

> Encontrei fontes ADVPL/TLPP neste projeto. Devo explorar os arquivos existentes antes de comecarmos o levantamento de requisitos?

Se o usuario concordar, va para o Passo 2.
Se nao, pule para o Passo 3.
Se NAO encontrar fontes, informe e va direto para o Passo 3.

### Passo 2: Explorar codigo — BUSCA DIRECIONADA

A exploracao NAO e um inventario do projeto. Busque APENAS o que e relevante ao tema que o usuario descreveu.

#### Etapa 1: Contexto rapido
- Read CLAUDE.md e/ou README.md — convencoes, prefixos, tabelas custom existentes
- Isso e SEMPRE feito (e rapido e informa o resto)

#### Etapa 2: Busca direcionada ao tema

Com base no que o usuario descreveu, busque APENAS o que tem relacao:

| Se o tema envolve... | Buscar... |
|---------------------|-----------|
| Um modulo especifico (ex: SIGAFAT) | Fontes dentro da pasta desse modulo |
| Rotina padrao (ex: MATA410) | PEs existentes dessa rotina, grep pela rotina |
| Tabela custom existente (ex: ZB0) | Fontes que referenciam essa tabela |
| Integracao com sistema externo | Fontes em pastas API/ ou com HttpPost/FWRest |
| Processo agendado | Fontes em pastas JOB/ |
| Relatorio | Fontes em Relatorio/ do modulo relevante |

NAO busque coisas sem relacao com o que esta sendo planejado.

#### Etapa 3: Enriquecimento com plugins (automatico)

Ao encontrar funcoes padrao Protheus no codigo (ex: MATA410, FWFormModel, MsExecAuto), use os plugins de documentacao para entender o contexto:

- **claude-tdn:tdn-docs** — buscar documentacao no TDN para funcoes/rotinas padrao encontradas, entender PEs disponiveis e parametros
- **protheus-toolkit:docs** ou **advpl-specialist:docs** — buscar funcoes nativas, tabelas SX, parametros MV referenciados no codigo

Se algum plugin nao estiver disponivel, siga sem ele usando o MCP `advpl-tlpp-mcp-docs` (docs, code-search, dicionario) e a exploracao do codigo.

Estas consultas sao automaticas e rapidas — enriquecem o resumo sem interferir no fluxo.

#### Etapa 4: Mini-review do codigo existente (perguntar ao usuario)

Se a exploracao encontrou codigo relevante, pergunte:

> Encontrei [N] fontes relacionados. Quer que eu faca uma analise rapida da qualidade desse codigo antes de prosseguir?

Se o usuario aceitar, use **advpl-specialist:review** ou **protheus-toolkit:review** (se indisponiveis, use a skill local `code-review` ou faca a analise diretamente) para identificar problemas que o PRD deveria considerar (ex: codigo legado que precisa refatoracao, vulnerabilidades, performance).

#### Etapa 5: Leitura dos fontes encontrados
- Read nos fontes relevantes (headers + logica principal)
- Entender: o que ja faz, como faz, o que pode ser reutilizado, o que precisa mudar
- Se encontrar utilitarios compartilhados usados pelo tema, ler tambem

#### Saida: Resumo focado

Apresente ao usuario APENAS o que e relevante para o PRD. Exemplo:

```
Encontrei codigo relacionado ao que voce descreveu:

- [Arquivo1.prw] — PE da MATA410 que ja valida campo X_CUSTOM
  -> Pode ser estendido para incluir a nova validacao
  -> Doc TDN: MATA410 aceita PE "MT410LOK" para validacao de linha
- [Arquivo2.tlpp] — API REST que ja faz POST para sistema externo
  -> Padrao de integracao que podemos seguir
- Tabela ZB0 (documentada no CLAUDE.md) — fila de pedidos
  -> Pode precisar de novos campos para esta feature

Convencoes do projeto: prefixo TEC, namespace custom.tecnoperfil.*
```

Se nao encontrar nada relevante, diga isso e siga para a entrevista.

### Passo 3: Entrevista conversacional

Inicie com uma pergunta aberta para entender o problema/necessidade:

> Para eu montar o PRD, me conta: **qual problema voce precisa resolver ou qual necessidade de negocio estamos atendendo?**

A partir da resposta, aprofunde naturalmente. Exemplos de perguntas de acompanhamento (adapte ao contexto):

- "Quem sao os usuarios que vao usar isso no dia a dia?"
- "Existe alguma rotina padrao do Protheus que esta relacionada?"
- "Isso precisa integrar com algum outro modulo ou sistema externo?"
- "Qual o volume de dados esperado?"
- "Existe alguma regra de negocio especifica que eu preciso entender?"

Faca NO MAXIMO 2-3 perguntas por vez. Aguarde a resposta antes de continuar.

#### Enriquecimento automatico durante a entrevista

Quando o usuario mencionar um **modulo Protheus** (ex: "Compras", "Faturamento", SIGACOM, SIGAFAT), use automaticamente **protheus-toolkit:business-modules** para carregar a referencia do modulo — tabelas, rotinas, PEs disponiveis, integracoes. Se o plugin nao estiver disponivel, siga sem ele usando o MCP `advpl-tlpp-mcp-docs` (product-docs-search, dicionario). Isso permite fazer perguntas mais especificas e informadas.

Quando o usuario descrever um **fluxo de negocio** (ex: "pedido vira nota fiscal que gera financeiro"), pergunte:

> Quer que eu consulte o fluxo padrao do Protheus para esse processo? Assim posso comparar com o que voce precisa e identificar onde a customizacao entra.

Se aceitar, use **protheus-toolkit:process** ou **advpl-specialist:process** para mapear o fluxo padrao e identificar gaps. Se indisponiveis, use o MCP `advpl-tlpp-mcp-docs` (product-docs-search).

### Passo 4: Aprofundamento adaptativo

Ao longo da entrevista, garanta que as 3 dimensoes abaixo foram abordadas. Nao pergunte em ordem rigida — encaixe naturalmente na conversa. Se o usuario ja respondeu algo espontaneamente, NAO repita.

#### Dimensao 1: Modulo e Tabelas

Garantir que ficou claro:
- Qual modulo Protheus (SIGACOM, SIGAFAT, SIGAFIN, SIGAPCP, SIGAEST, etc.)
- Quais tabelas padrao envolvidas (SC5, SC6, SF2, SD2, SE1, etc.)
- Se precisa de tabela custom (Z**), quais campos, tipos e tamanhos
- Se precisa de indices customizados (SIX)
- Se precisa de campos customizados em tabelas padrao (SX3)

#### Dimensao 2: Integracoes e Pontos de Entrada

Garantir que ficou claro:
- Se a solucao usa ou cria pontos de entrada (PEs)
- Se existem gatilhos SX7 envolvidos
- Se ha integracao entre modulos (ex: faturamento gera financeiro)
- Se usa MsExecAuto para automatizar rotinas padrao
- Se ha integracao com sistemas externos (REST, SOAP, arquivo)
- Se ha jobs/processos agendados

#### Dimensao 3: Multi-filial e Seguranca

Garantir que ficou claro:
- Se as tabelas sao compartilhadas (x-filial) ou exclusivas
- Se a solucao funciona para todas as filiais ou filiais especificas
- Se precisa de controle de acesso por grupo de usuarios
- Se ha campos sensiveis que precisam de auditoria

### Passo 5: Gerar o PRD

Com todas as informacoes coletadas, gere o PRD usando o template abaixo. Exiba o conteudo completo diretamente na conversa como texto Markdown.

Se uma secao nao se aplica, escreva "Nao se aplica" em vez de omiti-la.
Se houve exploracao no Passo 2, inclua a secao "Codigo Existente Relacionado".
Se informacoes estao faltando, sinalize como "A definir" no documento.

#### Enriquecimento automatico com plugins na geracao

Ao gerar o PRD, use automaticamente **protheus-toolkit:protheus-data-model** para validar se o modelo de dados proposto segue os padroes Protheus (xFilial, campos obrigatorios, tipos corretos).

Para a secao "Decisoes de Implementacao", consulte o plugin especializado conforme o tipo de customizacao:

| Se o PRD envolve... | Usar plugin | Para recomendar... |
|---------------------|------------|-------------------|
| Tela ou cadastro | **protheus-toolkit:protheus-mvc** | MVC vs AxCadastro, com justificativa |
| API REST | **protheus-toolkit:protheus-rest** | Padrao de endpoint, autenticacao, JSON |
| Job/processo batch | **protheus-toolkit:protheus-jobs** | Padrao de Job (RpcSetEnv, controle de execucao) |
| Relatorio | **protheus-toolkit:protheus-reports** | TReport vs FWMSPrinter vs FwPrinterXlsx |
| Tela com browse/grid | **protheus-toolkit:protheus-screens** | Tipo de browse/grid adequado |

Consulte APENAS o plugin pertinente ao tipo da customizacao — nao carregue todos.

Se qualquer plugin desta etapa nao estiver disponivel, siga sem ele usando o MCP `advpl-tlpp-mcp-docs` e a exploracao do codigo existente.

---

## Template do PRD

```markdown
# PRD: [Titulo descritivo da customizacao]

**Modulo**: [SIGACOM/SIGAFAT/SIGAFIN/etc.]
**Cliente**: [Nome do cliente se identificado]
**Data**: [Data atual]
**Status**: Rascunho

---

## 1. Descricao do Problema

[Problema ou necessidade de negocio que motivou esta customizacao. Foque no "por que", nao no "como".]

## 2. Solucao Proposta

[Visao geral da solucao em 2-3 paragrafos. O que sera construido e como resolve o problema.]

## 3. Historias de Usuario

1. Como [ator], eu quero [funcionalidade], para que [beneficio].
2. Como [ator], eu quero [funcionalidade], para que [beneficio].
3. ...

## 4. Modulo e Escopo

### Rotinas envolvidas

| Tipo | Rotina | Descricao |
|------|--------|-----------|
| [Nova/Alteracao/PE] | [Nome] | [O que faz] |

### Rotinas padrao Protheus impactadas

| Rotina | Modulo | Impacto |
|--------|--------|---------|
| [MATA410/MATA010/etc.] | [Modulo] | [Como e afetada] |

## 5. Codigo Existente Relacionado

> Secao incluida apenas se houve exploracao de codigo no Passo 2.

| Arquivo | O que faz | Relacao com este PRD |
|---------|-----------|---------------------|
| [caminho/arquivo.prw] | [Descricao] | [Reutilizar/Estender/Impactado] |

## 6. Modelo de Dados

### Tabelas customizadas

| Alias | Descricao | Compartilhamento |
|-------|-----------|-----------------|
| [Z**] | [Descricao] | [Compartilhada/Exclusiva] |

### Campos customizados (SX3)

| Campo | Tabela | Tipo | Tamanho | Titulo | Descricao |
|-------|--------|------|---------|--------|-----------|
| [XX_CAMPO] | [Alias] | [C/N/D/L/M] | [Tam] | [Titulo] | [Descricao] |

### Indices customizados (SIX)

| Alias | Ordem | Chave | Descricao |
|-------|-------|-------|-----------|
| [Z**] | [N] | [Campos] | [Para que serve] |

### Gatilhos (SX7)

| Campo origem | Sequencia | Regra | Campo destino |
|-------------|-----------|-------|--------------|
| [Campo] | [Seq] | [Expressao] | [Campo] |

## 7. Pontos de Entrada e Integracoes

### Pontos de Entrada

| PE | Rotina-base | Finalidade |
|----|------------|-----------|
| [Nome do PE] | [Rotina padrao] | [O que faz] |

### Integracoes entre modulos

[Fluxo: ex. "Pedido de Venda (SIGAFAT) -> Nota Fiscal (SIGAFAT) -> Financeiro (SIGAFIN)"]

### Integracoes externas

| Sistema | Protocolo | Direcao | Descricao |
|---------|-----------|---------|-----------|
| [Sistema] | [REST/SOAP/Arquivo] | [Envia/Recebe/Bidirecional] | [O que integra] |

### Automacoes (MsExecAuto / Jobs)

| Tipo | Rotina | Frequencia | Descricao |
|------|--------|-----------|-----------|
| [Job/MsExecAuto] | [Nome] | [Tempo real/Agendado] | [O que faz] |

## 8. Regras de Filial e Seguranca

- **Filiais**: [Todas / Especificas — quais]
- **Compartilhamento de tabelas**: [xFilial padrao / Compartilhada]
- **Controle de acesso**: [Grupos / Permissoes necessarias]
- **Auditoria**: [Campos ou operacoes que precisam de log]

## 9. Decisoes de Implementacao

| Decisao | Escolha | Justificativa |
|---------|---------|--------------|
| Abordagem de tela | [MVC / AxCadastro / Browse / N/A] | [Por que] |
| Linguagem | [ADVPL / TLPP] | [Por que] |
| Protocolo de API | [REST / SOAP / N/A] | [Por que] |
| Acesso a dados | [Embedded SQL / DbSeek / MpSysOpenQuery] | [Por que] |
| Convencao de nomes | [Prefixo usado] | [Padrao do cliente] |

## 10. Fora do Escopo

- [Item explicitamente excluido]

## 11. Observacoes Adicionais

[Riscos, premissas, dependencias, versao minima do Protheus, etc.]
```

---

### Passo 6: Oferecer gravacao em arquivo

Apos exibir o PRD completo na conversa, pergunte:

> Gostaria de gravar isso em um arquivo?

Se o usuario responder sim:
1. Sugira `.claude/plans/<slug>/prd.md` — se nao houver plano, pergunte ticket + descricao curta para montar o slug (convencao: `<feature-slug>[-<ticket>]`)
2. Pergunte se quer usar esse caminho ou outro
3. Use a ferramenta Write para criar o arquivo

Se responder nao, siga para o Passo 7.

### Passo 7: Validacao do PRD (perguntar ao usuario)

Apos exibir o PRD (e opcionalmente gravar), pergunte:

> Quer que eu faca um interrogatorio no PRD para validar as decisoes?

Se o usuario aceitar, invoque a skill **interrogatorio-advpl** passando o PRD como contexto. Ela vai questionar cada aspecto do plano ate garantir que nao ficou nenhuma lacuna.

Se o usuario recusar, encerre normalmente.

## Regras

1. **NUNCA crie GitHub Issues** — output e sempre texto na conversa + arquivo opcional
2. **Sempre exiba o PRD completo na conversa primeiro** — so depois ofereca gravar
3. **Respeite o estilo do cliente** — se CLAUDE.md ou fontes indicam Hungarian notation, prefixos, Protheus.doc headers, namespaces TLPP, mencione nas Decisoes de Implementacao
4. **Entrevista adaptativa** — nao despeje todas as perguntas de uma vez. Conversa natural.
5. **Maximo 2-3 perguntas por mensagem** — aguarde resposta antes de continuar
6. **Se informacoes suficientes**, gere o PRD sem forcar perguntas — sinalize lacunas como "A definir"
7. **Exploracao direcionada** — busque APENAS codigo relevante ao tema, nao inventarie o projeto
8. **Secoes nao aplicaveis** = "Nao se aplica" (nao omitir a secao)
