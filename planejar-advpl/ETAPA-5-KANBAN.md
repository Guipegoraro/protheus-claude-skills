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
6. Confirme que o provider tem **comentarios por card** (ou equivalente). Nao tendo, os modos de aprovacao abaixo perdem o canal de conversa: avise o usuario e combine o substituto (secao de comentarios dentro do proprio card) antes de seguir.

## Modo de aprovacao (perguntar SEMPRE)

Antes de criar ou mover qualquer card, pergunte ao usuario qual modo vale para ESTA sessao. Pergunte mesmo quando o `plano.md` ja registra um modo — mostre o registrado como sugestao e espere a resposta. Modo herdado em silencio e o mesmo que nao ter modo.

| Modo | O que muda |
|------|-----------|
| **Livre** | Card nasce em TODO; a sessao implementa sem parar para aprovacao |
| **Aprovacao de entrada** | Todo card nasce em AGUARDANDO APROVACAO; nada entra em DOING sem estar APROVADO |
| **Entrada + entrega** | Alem da entrada, card implementado para em EM REVISAO e so vai para DONE com o OK do usuario |

Registre o modo escolhido no `plano.md` (linha **Kanban**) com a data.

### Estados por modo

- **Livre:** TODO → DOING → DONE
- **Entrada:** AGUARDANDO APROVACAO → APROVADO → DOING → DONE
- **Entrada + entrega:** AGUARDANDO APROVACAO → APROVADO → DOING → EM REVISAO → DONE

Alem desses, dois estados **transversais** aos modos — TRABALHO HUMANO e AGUARDANDO TERCEIROS — descritos adiante.

Provider sem colunas customizaveis: represente o estado nesta ordem de preferencia — coluna propria → label/tag → prefixo no titulo (`[AGUARDANDO] TASK-007: ...`) → comentario marcador. Registre no `plano.md` qual representacao ficou.

### Invariantes do modo de aprovacao

- **Nada entra em DOING sem APROVADO.** Com a fila parada esperando o usuario, a sessao NAO pega outro card "para adiantar": ela para e diz exatamente o que esta travado e em quem.
- **Aprovacao e por card e explicita.** "pode seguir" aprova o card em discussao, nao a fila. Para liberar em lote o usuario diz quais (ou "todos os da camada N") — e a sessao repete a lista aprovada antes de mover.
- **Card aprovado que muda volta a AGUARDANDO APROVACAO** — escopo cresceu, criterio de aceite alterado, dependencia nova — com comentario dizendo o que mudou.
- **Carimbo de aprovacao no card:** comentario `Aprovado por <usuario> em <data>` — mesma disciplina de fonte do escopo declarado.
- **Nao aprovado** fica (ou volta) em AGUARDANDO APROVACAO com comentario `NAO APROVADO — <motivo>`. Coluna separada de reprovado nao paga o proprio custo.
- **Enquanto a fila espera**, pode preparar (pesquisa, brief, rascunho de teste) — implementar, nao.

### Comentarios sao o canal do modo de aprovacao

Nos modos com aprovacao o card conversa: a sessao escreve comentarios, o usuario responde neles, e a sessao LE antes de agir.

**Escreva comentario:**
- **ao criar o card** — o que voce entendeu, premissas, o que fica de fora, perguntas abertas, e o que o usuario precisa decidir para aprovar
- **ao mover de estado** — por que esta movendo e a evidencia (teste verde, gate humano, commit)
- **ao concluir** — o que foi feito, arquivos tocados, como validar
- **quando o card mudar** — antes de pedir re-aprovacao

**Leia comentario:**
- **antes de comecar** um card — o usuario pode ter respondido dias depois da criacao
- **antes de mover** para EM REVISAO ou DONE
- **a cada retomada de sessao** — varra os cards ativos por comentario novo ANTES de decidir o que fazer

Comentario do usuario vence o texto do card: contradisse descricao ou criterio de aceite, atualize o card conforme o comentario e responda num comentario dizendo o que mudou. Duas excecoes que nao se aplicam direto: comentario que pede **feature nova** e candidata a escopo — conversar e aprovar pela regra do escopo declarado antes de virar card; comentario que traz **regra de negocio com fonte do cliente** vira RN/CB no `casos-e-regras.md`, e o card passa a citar o ID.

### Flags de conversa: `comentado` e `pergunta`

Duas marcas, uma em cada sentido, validas em **qualquer** modo — comentario tambem acontece no modo livre:

- **`comentado`** (usuario → sessao): o usuario comentou e quer resposta. A sessao limpa quando **responde**, nao quando le — flag ligada significa "pendente de resposta minha", nunca "nao lido".
- **`pergunta`** (sessao → usuario): duvida que trava a implementacao (pedido de aprovacao ja tem estado proprio). Quem limpa e o usuario, ao responder.

Representacao: label/tag do provider → prefixo no titulo → marcador no comentario. **Nunca coluna** — o card ficaria em dois lugares ao mesmo tempo.

**Flag esquecida nao pode perder comentario.** A varredura de retomada nao confia so na flag: compare tambem `updated_at` / data de modificacao dos cards com a ultima passagem da sessao — em provider versionado em git, um diff na pasta de tasks desde o ultimo commit da sessao anterior mostra exatamente o que o usuario mexeu. A flag e o sinal de INTENCAO ("quero resposta"); o timestamp e o piso que pega o que a flag deixou passar.

## Estados de espera: quando a bola nao esta com a sessao

Dois estados **transversais** — o card entra neles vindo de qualquer ponto do fluxo e volta ao estado de origem quando destrava. Valem em qualquer modo de aprovacao.

| Estado | Quando | Exemplos |
|--------|--------|----------|
| **TRABALHO HUMANO** | A tarefa e do usuario e nao depende da sessao | criar campo/parametro/indice no Configurador, rodar o roteiro do gate humano no TST, reiniciar servidor, compilar em ambiente fora do alcance da IA |
| **AGUARDANDO TERCEIROS** | A tarefa depende de fora | resposta do cliente por e-mail/reuniao, ticket no suporte TOTVS, fornecedor, TI do cliente |

Campo **Responsavel** obrigatorio nos dois — quem exatamente (`Camila (cliente)`, `ticket TOTVS 12345`, `usuario — Configurador`). E o gancho da cobranca.

### Regras dos dois estados

- **Bloqueiam quem depende.** Card em espera trava seus dependentes (campo **Dependencias** / `depends_on` do provider) — e o motivo de existir: nao se implementa codigo que usa campo que ainda nao existe no dicionario.
- **So o usuario fecha.** Nunca infira que foi feito — pergunte. Onde da para verificar (campo no SX3, parametro no SX6), **verifique antes de fechar**: skill `genericquery` quando o projeto tiver `.genericquery.json`, ou peca a consulta ao usuario. Evidencia, nao relato.
- **Spec nao duplica.** Campo/parametro continua especificado no `pre-producao.md` (tipo, tamanho, titulo) e regra no `casos-e-regras.md`; o card CITA. Mesma definicao em dois lugares diverge.
- **Nao contam no limite de DOING** — mas fila inteira travada nao vira desculpa para pegar card "para adiantar": pare e diga o que trava e em quem. Card independente e liberado segue normal.

### Cobranca do AGUARDANDO TERCEIROS

O card registra **o que foi perguntado, por qual canal (e-mail / ticket / reuniao) e a data da pergunta**. A cada retomada de sessao, ANTES de perguntar o que fazer, liste o que esta parado ha mais de **3 dias uteis**: quem, desde quando, o que trava. Espera sem data vira arqueologia de e-mail duas semanas depois.

O texto da pergunta continua em `perguntas-cliente.md` — o card e o rastreador do prazo, o documento e a fonte da pergunta e da resposta.

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
| **Estado** | TODO / DOING / DONE, mais AGUARDANDO APROVACAO / APROVADO / EM REVISAO conforme o modo e TRABALHO HUMANO / AGUARDANDO TERCEIROS quando a bola sai da sessao — ou as colunas equivalentes do provider |
| **Responsavel** | So nos estados de espera: quem exatamente destrava |

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

1. Leia os comentarios do card e as flags e confirme o estado de entrada: TODO no modo livre, APROVADO nos demais
2. Mova o card para DOING no provider
3. Ao concluir, mova para DONE — ou para EM REVISAO, no modo entrada + entrega — registrando no card: o que foi feito, arquivos modificados e observacoes
4. Travou em algo que depende do usuario ou de terceiro → mova para TRABALHO HUMANO / AGUARDANDO TERCEIROS com Responsavel e data, em vez de deixar apodrecendo em DOING
5. Necessidade nova de campo/parametro/indice/consulta F3 no meio de um card → skills `protheus-configurador-dicionario` / `protheus-consulta-padrao` (elas gravam o `pre-producao.md`) e o card do Configurador nasce em TRABALHO HUMANO, bloqueando quem depende dele

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
