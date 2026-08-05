---
name: interrogatorio-advpl
description: Use when user wants to stress-test a Protheus customization plan, validate design decisions for ADVPL/TLPP development, or mentions "interrogatorio", "interroga", "grill", "questiona", "valida o plano", "stress-test do plano".
---

Interrogue-me implacavelmente sobre cada aspecto deste plano de customizacao Protheus ate chegarmos a um entendimento compartilhado. Percorra cada ramo da arvore de decisoes, resolvendo dependencias entre decisoes uma a uma. Para cada pergunta, forneca sua resposta recomendada.

Faca as perguntas uma de cada vez.

Se uma pergunta pode ser respondida explorando o codebase do projeto, explore o codebase primeiro.

## Dimensoes obrigatorias para questionar

Alem das decisoes gerais de design, sempre cubra estas dimensoes especificas do Protheus:

| Dimensao | Perguntas-chave |
|----------|----------------|
| **Modelo de dados** | Tabela padrao ou custom (Z**)? Quais campos? Indices (SIX)? Relacionamentos? |
| **Multi-filial** | Tabela compartilhada ou exclusiva? `xFilial` correto? Impacto em outras filiais? |
| **Abordagem** | MVC (FWFormModel/FWFormView) ou tradicional (AxCadastro/MBrowse)? REST API? Job? Por que? |
| **Integracao entre modulos** | Impacto fiscal? Financeiro? Contabil? Estoque? Qual o fluxo completo? |
| **Pontos de entrada** | Existe PE que afeta esta rotina? Devemos criar PE para extensibilidade? |
| **Concorrencia** | RecLock/MsUnlock? Begin Transaction? Risco de deadlock em operacoes batch? |
| **Performance** | Volume de dados esperado? Precisa de indice dedicado? DbSeek vs Embedded SQL? |
| **Dicionario** | Mudancas em SX3, SIX, SX1, SX5, SX7? Registrar em pre-producao.md (Configurador — nunca via fonte)? |
| **Seguranca** | Controle de acesso (CFGA080)? Campos sensiveis? Validacao de entrada? |
| **Compatibilidade** | Quebra customizacoes existentes do cliente? Impacto em atualizacoes futuras? |

## Regras

- Nao aceite respostas vagas como "vamos ver depois" — force uma decisao ou registre explicitamente como pendencia critica.
- Perguntas que dependem de decisao do CLIENTE (regra de negocio sem fonte) nao ficam em aberto no chat: registre em `.claude/plans/<slug>/perguntas-cliente.md` como pergunta aberta ao cliente, e enquanto nao houver resposta implemente o comportamento mais permissivo com log/aviso (nunca bloqueio decidido por conta propria).
- Se o plano envolve mais de um modulo, mapeie o fluxo completo antes de detalhar cada parte.
- Se encontrar inconsistencias no plano, aponte imediatamente e sugira correcao.
- Ao final, resuma todas as decisoes tomadas e pendencias abertas em formato de checklist.
- Ao terminar o checklist, apresente o resumo e NAO aja sobre o plano ate o usuario confirmar que ha entendimento compartilhado.

<!-- Primitiva base: skills/grilling (esta skill = grilling + dimensoes Protheus). Mudou a primitiva? Refletir aqui. -->
