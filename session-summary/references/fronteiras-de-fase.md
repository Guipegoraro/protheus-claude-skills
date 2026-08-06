# Fronteiras de fase — continuar, limpar, resumir ou delegar

Uma **fase** e um bloco de trabalho dentro da sessao — o interrogatorio, a implementacao, o QA. A definicao e vaga de proposito: a fase termina quando se pensa "ok, isso ta fechado".

A **fronteira de fase** e o intervalo entre duas fases — e e o UNICO lugar onde a decisao abaixo pertence. No meio da fase nao ha decisao a tomar: continue, ou fatie o que resta em subagentes. Compactar no meio da fase faz o agente perder o fio.

## As cinco opcoes

| Opcao | O que faz |
| --- | --- |
| **Continuar** | Fica na sessao. Nenhuma troca de contexto. |
| **/clear** | Esvazia a janela e comeca do zero. |
| **/session-summary → /clear → /session-resume** | O par local de portabilidade: grava resumo denso, limpa, recarrega (o resumo referencia os artefatos do plano em vez de duplica-los). |
| **Subagente** | Manda a tarefa para janela propria e recebe relatorio. |
| **/compact** | Comprime este contexto e segue com o resumo. |

## A arvore (de cima para baixo; o primeiro SIM vence)

1. **Da para continuar nesta sessao?** Sim quando a proxima fase precisa desta como **fonte primaria** (interrogatorio → implementacao e o caso classico: a implementacao quer o raciocinio na integra, nao um resumo dele) ou quando ainda ha bastante janela util. Continuar nao custa nada e nao perde nada — descarte esta opcao antes de qualquer outra.
2. **O contexto e irrelevante para o que vem?** Exploracao, becos sem saida, tudo descartavel? **/clear** — o movimento mais barato. Errar aqui e mao unica: limpar contexto RELEVANTE perde o PORQUE do que foi construido, e reler o diff nao devolve.
3. **Algo precisa viajar?** Outra sessao/maquina, outro repositorio, um colega, ou um desvio descoberto no meio da fase que nao pode descarrilar a atual → **/session-summary** (o resumo e o artefato portavel; em projeto com plano, ele referencia `.claude/plans/<slug>/` em vez de copiar). O arquivo `session-resume*.md` e efemero por natureza — consumido pelo `/session-resume` e apagavel depois; **nao ha regra de commita-lo**.
4. **A tarefa pode rodar sem voce?** Escopo fechado o bastante para rodar AFK, sem direcao no meio → **subagente**, e esta sessao fica intacta. Revisao adversarial e o caso padrao.
5. **Senao, /compact** — contexto relevante, mesma sessao, e voce precisa continuar no loop. Passe instrucao (`/compact vamos para o QA da area X`) para o resumo preservar o que a proxima fase precisa. O /compact e o **default, nao o primeiro reflexo**: as quatro perguntas acima sao todas mais baratas ou mais precisas. O failure mode de comecar por aqui e uma sessao nova confiantemente errada sobre uma decisao que o resumo achatou.

## Fonte primaria e secundaria

Todo movimento exceto Continuar converte uma **fonte primaria** (a sessao como aconteceu) em **secundaria** (um resumo dela): menos ruido e mais janela, ao custo de perda. Por isso a pergunta 1 vem primeiro — so pague a perda quando ficar custa mais do que economiza.

As perguntas tem julgamento embutido — a mesma fronteira pode sair diferente em dois dias. O valor esta em pergunta-las EM ORDEM, na fronteira, e nao no meio do trabalho.

<!-- Adaptado de ask-matt/PHASE-BOUNDARIES.md, https://github.com/mattpocock/skills (MIT, Matt Pocock) -->
