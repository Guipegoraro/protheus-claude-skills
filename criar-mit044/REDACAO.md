# Redação da MIT044, seção a seção

Fórmulas extraídas de MIT044 aprovadas. Consultar durante o passo 4 da [`SKILL.md`](SKILL.md);
as regras de conteúdo de lá (linguagem do cliente, sem travessão, exemplo não é fato) valem por
cima de tudo aqui.

## Voz

- Impessoal e no futuro para o que será construído ("será construída", "o sistema apresenta").
  Nunca primeira pessoa. Presente para o processo atual.
- Bullets terminam em `;` e o último da lista em `.`.
- O que ainda não está decidido aparece por escrito: "Pendente de definição com [o fiscal do
  cliente / a implantação]", nunca omitido.

## Processo Atual (3 a 5 parágrafos)

Descreve a dor, no presente, sem citar a solução:

1. como o processo funciona hoje, áreas envolvidas, porquê histórico se houver;
2. os controles manuais ou paralelos (planilha, conferência a mão, cálculo fora do sistema);
3. a consequência: retrabalho, risco de erro, falta de rastreabilidade.

Fechar dizendo se há MIT041 ou outra MIT044 vinculada.

## Processo Proposto (3 a 4 parágrafos)

Abre com a fórmula consagrada: "Com a entrada em operação do Protheus, ...". Descreve o que
passa a existir na ordem em que o usuário vive o processo; regras que variam por parâmetro
ficam por último. Sem detalhe de implementação.

## Parametrizações

Abertura fixa: "O correto funcionamento da rotina depende das seguintes configurações e
premissas sistêmicas:". Depois, os pré-requisitos (cadastros, TES, parâmetros, séries). Fecho:
"Serão avaliados, na especificação técnica, eventuais parâmetros próprios da rotina (SX6) para
[valores padrão pertinentes]."

## Execução: cinco blocos, nesta ordem

| Bloco | Formato | Como escrever |
|---|---|---|
| Objetivos do negócio | 4 bullets | verbo no infinitivo: Automatizar, Garantir, Eliminar, Reduzir |
| Fluxo do processo | 6 a 8 passos numerados | cada passo começa com "O usuário..." ou "O sistema...", em ordem cronológica |
| Premissas e Restrições | 5 a 8 bullets | o que limita o escopo e o que acontece quando é violado |
| Plano de teste | 6 a 8 linhas | sempre cenário e resultado esperado, incluindo caso de erro e um de regressão |
| Rastreabilidade | 1 parágrafo | MIT041/MIT044 relacionadas e o que cada uma fornece |

## Customizações: blocos nesta ordem

- **Periodicidade**: marcar uma linha só; descrever a forma entre parênteses ("Execução sob
  demanda (o usuário executa pela tela)").
- **Onde será executada**: parágrafo com módulo e menu, mais tabela rotina/descrição. Fonte sem
  nome ainda: "A definir (padrão [cliente], [módulo])".
- **Funcionalidades**: bullets `RF01: ...;` numerados sem pular. Cada RF é uma capacidade
  observável pelo usuário, não uma tarefa de desenvolvimento.
- **Premissas e restrições técnicas**: cabe vocabulário semi-técnico (reutilização de rotina
  padrão, campo criado via Configurador), ainda sem código.
- **Protótipo de tela**: figuras com legenda, mais parágrafo descrevendo painéis, colunas e
  ações; fechar com "O protótipo definitivo (layout e colunas) será detalhado na especificação
  técnica."
- **Anexos**: pares descrição/observação; a observação marca o que está pendente de envio pelo
  cliente.

## Histórico de Versões

Registra a vida do documento, não do desenvolvimento: emissão inicial, revisões após validação,
ajustes pedidos pelo cliente. Uma linha por versão (data, `1.00`/`1.01`/`2.00`, autor, o que
mudou em uma frase). Ao revisar documento já enviado, acrescentar linha; nunca reescrever as
anteriores.

## Tamanho de referência

MIT044 aprovadas têm por volta de 90 parágrafos de conteúdo e 7 tabelas. Documento muito mais
curto indica seção vazia; muito mais longo indica detalhe técnico vazando para o documento de
negócio.

<!-- Fórmulas adaptadas de github.com/brunobrigidovilanova/protheus-claude-skills (MIT) -->
