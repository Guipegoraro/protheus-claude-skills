# Template e regras do decisoes-cliente.md

## Estrutura recomendada

```text
COMPILADO DE DECISÕES - [NOME DA FEATURE]
Ticket: [referência externa - tspace/jira/e-mail]

================================================================
1. [TEMA - ex: MODELO DE DADOS]
================================================================

1.1 [Decisão direta em uma frase. Quando o cliente vai conferir
    no Configurador, cite parâmetro/tabela/campo com nome exato.]

1.2 [Quando a decisão tem motivo importante, inclua "Motivo: ..."
    em frase curta logo abaixo.]

================================================================
2. [TEMA - ex: CÁLCULO X]
================================================================

2.1 ...
2.2 ...

================================================================
N. PARÂMETROS NOVOS PARA CRIAR NO CONFIGURADOR
================================================================

NOME_PARAM   default "valor"
    Descrição curta

JÁ EXISTENTES - só validar default em PROD:
- PARAM_X  -> deve ser "valor esperado"

================================================================
*** PERGUNTAS EM ABERTO ***
================================================================

1) [Pergunta direta para o cliente, com contexto curto + qual
   comportamento está em vigor enquanto não responde.]

================================================================
CHANGELOG
================================================================

[YYYY-MM-DD] - Versão inicial enviada ao cliente.

[YYYY-MM-DD] - [Descrição da mudança em uma frase].
    Fonte: [e-mail Fulano / ticket 00011638 / ata reunião DD/MM].
    Item afetado: seção X.Y.
```

## Temas tipicos por modulo

Use como ponto de partida, ajuste ao caso:

- **Financeiro / Faturamento**: modelo de dados, formula de calculo,
  regras especiais (cliente/natureza/tipo), parametros, como o
  numero/saldo e atualizado, integracoes.
- **Compras**: modelo de dados, regras de aprovacao, parametros de
  alcada, integracoes (portal/ERP externo), tela vs job.
- **Estoque/PCP**: estrutura de produto, regras de movimentacao,
  regras de bloqueio/liberacao, atualizacoes em massa.
- **Importacao (EIC)**: chaves de processo (HAWB customizado vs
  padrao), integracoes com despachantes, fluxo de aprovacao.

## Regras de linguagem (load-bearing)

- **Participio passado impessoal** — mesma voz dos apontamentos:
  "Considerados apenas titulos baixados", "Excluidos titulos do
  tipo INV". Evitar primeira pessoa ("decidimos", "fizemos").
- **Citar nomes de cliente/processo** quando ja sao conhecidos do
  cliente: "clientes 42671051 e 52085074", "processo 59533".
- **Citar parametros** com codigo exato do SX6 (`ASC_ASC06A001`,
  `MV_PAR01`) — o cliente confere no Configurador.
- **Citar tabelas e campos custom** com prefixo Z** (SZN, ZN_VLRNUM)
  — sao reais e podem aparecer em telas/relatorios/queries.
- **NAO citar** nomes de funcoes ADVPL/TLPP, classes, namespaces,
  variaveis internas, design patterns ou decisoes de implementacao
  (lock-by-name, idempotencia, begin transaction, FWPreparedStatement,
  alias temporario, etc). Se nao agrega ao entendimento do cliente,
  fica de fora.
- **Acentuacao correta** — o documento e lido por humano, nao por
  AppServer. `cálculo`, `parâmetro`, `função`, `decisões`, etc.
- **Pendencias para o cliente** ficam no bloco final "PERGUNTAS EM
  ABERTO". Sempre inclua: pergunta, contexto curto, qual
  comportamento esta em vigor enquanto nao responde.

## Changelog — formato e regras

O bloco CHANGELOG fica no fim do arquivo. Cada entrada:

1. **Data ISO** (`YYYY-MM-DD`)
2. **Descricao em uma frase** do que mudou.
3. **Fonte** (em linha indentada): de onde veio a mudanca —
   e-mail, ticket, ata de reuniao, nome da pessoa. **Nunca
   omitir** — sem fonte a mudanca nao tem rastreabilidade.
4. **Item afetado**: numero da secao + tema (ex: "secao 6.5
   cobertura de POs sem SW6").

Ordem cronologica: mais antigo no topo, mais novo no fim. **Nunca
reescreva entrada antiga** — se uma decisao foi reposta, registre
uma nova linha "decisao X revertida apos resposta do Fulano".

Quando uma pergunta em aberto for respondida pelo cliente:

1. Move o item da secao "PERGUNTAS EM ABERTO" para a secao tematica
   apropriada (vira decisao consolidada).
2. Registra no changelog: `[DATA] - Q1 respondida por Fulano,
   mantida soma direta. Fonte: e-mail 12/05. Item afetado: secao 2.1.`
3. Ajusta o fonte ADVPL se a resposta mudou comportamento.
