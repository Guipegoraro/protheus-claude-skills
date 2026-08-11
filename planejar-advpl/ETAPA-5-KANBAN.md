# Etapa 5: Kanban

Ramo da skill [`planejar-advpl`](SKILL.md) para a Etapa 5 — o resto do processo (etapas 1-4 e 6-8) esta no `SKILL.md`.

**Objetivo:** Quebrar o PRD em tarefas atomicas e rastrear a implementacao.

## O kanban mora no kanban provider da maquina

**Kanban provider** = a ferramenta de board disponivel nesta maquina/sessao (MCP, plugin, skill ou CLI) que cria, move e consulta cards. Havendo provider, ele e a **fonte da verdade** do kanban: os cards vivem la, e nenhum markdown paralelo repete a lista. O `kanban.md` na pasta do plano e o **fallback** — usado so quando nao existe provider nenhum. Dois lugares com os mesmos cards divergem na primeira sessao.

### Descoberta do provider (primeiro passo da etapa, sempre)

1. Procure o provider entre as ferramentas desta sessao: tools MCP, plugins e skills cujo nome ou descricao fale de kanban, board, card, task ou issue; confira tambem o `.mcp.json` e o `settings.json` do projeto.
2. **Um candidato** → use-o.
3. **Mais de um** → pergunte ao usuario qual board recebe esta customizacao. Escolher sozinho espalha card de cliente em ferramenta errada.
4. **Nenhum** → crie `kanban.md` na pasta do plano a partir de `templates/kanban.md` (nesta skill) e siga o resto deste arquivo tratando TODO/DOING/DONE como os estados do card.
5. Nomeie o board/projeto do provider com o `<slug>` da customizacao, e registre no `plano.md` (linha **Kanban** do cabecalho): provider + identificacao do board (id, url ou nome), ou `kanban.md (sem provider)`. A sessao seguinte retoma por essa linha — provider nao registrado e board perdido.

## Criacao do kanban

Com base no PRD, crie tarefas atomicas — cada uma implementavel em uma sessao de trabalho.

### Contrato do card (vale em qualquer provider)

Nenhum provider tem exatamente estes campos. Mapeie cada um para o que ele oferece e jogue o resto no corpo do card — o contrato e o que nao pode faltar; o formato e problema do provider.

| Campo | Conteudo |
|-------|----------|
| **Titulo** | `TASK-nnn: [titulo descritivo]` — a numeracao TASK-nnn e preservada mesmo quando o provider tem id proprio, porque PRD, QA, briefs e commits citam por ela |
| **Descricao** | O que fazer |
| **Origem** | Requisito do PRD + linha `E-n` do escopo declarado — card sem origem nao entra |
| **Arquivos** | Fontes que serao tocados (`path/to/file.prw`) |
| **Complexidade** | Baixa / Media / Alta |
| **Dependencias** | Nenhuma / TASK-nnn |
| **Camada** | N (ver abaixo) |
| **Regras** | RN-xx / CB-xx do `casos-e-regras.md`, quando existir |
| **Criterio de aceite** | O que define "pronto" — SEMPRE inclui o teste correspondente; task sem teste nao fecha, e kanban sem esse contrato vira lista de intencoes |
| **Estado** | TODO / DOING / DONE, ou as colunas equivalentes do provider |

### Camadas e gates

Ordem bottom-up (ex: parsers → analise → motor → telas → integracao). Camada so FECHA com testes verdes + gate aprovado; a camada seguinte NAO inicia com gate aberto. Gate reprovado → o bug vira teste que reproduz (bug-spec em `fixes/`) → re-gate.

- **Evidencia de maquina** (testes verdes) fecha camadas baixas: logica pura, parsers, calculos. **Gate humano** e obrigatorio em camada que toca carteira/fiscal/faturamento — a IA nao tem acesso ao ambiente do cliente.
- A ULTIMA task de cada camada entrega o ROTEIRO do gate humano: script do que o usuario executa e confere — nunca "cliquei e pareceu ok".
- Revisao adversarial recorrente: rodada numerada + achados contados (a) no plano/kanban antes de executar, (b) ao fim de CADA camada sobre o fonte, (c) antes do deploy. Adversarial que nao acha mais nada = artefato maduro.
- Spike sem data mas no caminho critico: EXPLICITO como task propria, senao bloqueia a camada em silencio.

Registre o mapa de camadas onde o provider aceitar (descricao do board, card-indice ou epico); sem provider, a tabela de camadas do `templates/kanban.md` cumpre o papel.

### Fatiamento tracer-bullet

Cada card deve atravessar o caminho completo (fonte → dicionario → tela/endpoint) e ser demonstravel/testavel sozinho — nada de cards "so backend" ou "so tela" que dependem um do outro para provar valor. Excecao: refactors largos usam o padrao expand–contract (expandir estrutura nova / migrar em lotes / contrair removendo a antiga), um card por fase.

### Passada de corte (antes de comecar a implementar)

Cada card cita no campo **Origem** o requisito do PRD e a linha `E-n`. Card sem origem sai. Card que so existe porque "ja que estamos aqui" sai.

## Durante a implementacao

Ao trabalhar em um item:

1. Mova o card de TODO para DOING no provider
2. Ao concluir, mova para DONE registrando no card: o que foi feito, arquivos modificados e observacoes
3. Necessidade nova de campo/parametro/indice/consulta F3 no meio de um card → skills `protheus-configurador-dicionario` / `protheus-consulta-padrao` (elas gravam o `pre-producao.md`)

No fallback `kanban.md`, mover = recortar a task para a secao correspondente e atualizar `**Ultima atualizacao**` no topo.

### Regras do kanban

- Maximo 2 itens em DOING simultaneamente
- Se uma tarefa crescer demais, quebre em sub-tarefas
- Trabalho nao previsto descoberto na implementacao: **necessario** para fechar um card existente (sem ele o criterio de aceite nao passa) → nova TASK com a mesma origem. **Feature nova** → conversar e aprovar antes de virar card; sem o sim, vai para `## Fora de escopo / rejeitado` do plano.md
- Bug descoberto apos o kanban montado: criar bug-spec em `fixes/` (leia `templates/bug-spec.md` nesta skill) — a spec dirige a correcao; causa raiz e achado de investigacao

## Execucao delegada (opcional, portes medio/grande)

Quando as tasks forem implementadas por agentes (subagente ou bridge externo), a sessao principal vira planner/reviewer e o par que disciplina a execucao e:

- **Brief por task**: leia `templates/brief.md` (nesta skill) — auto-contido, fonte normativa, comandos literais, brief >1 pagina = task gorda.
- **Agente executor do projeto**: leia `templates/agente-executor.md` (nesta skill) — instanciado UMA vez em `.claude/agents/` do projeto, versionado; as regras operacionais moram nele, nao repetidas em cada brief.
- **Invariante**: nenhuma entrega de agente fecha sem analise da sessao principal (checklist objetivo) — o revisor valida FATOS em lote (campo por dicionario, assinatura por fonte real) antes de devolver rodada, e refaz a varredura em vez de confiar no relatorio do agente.
