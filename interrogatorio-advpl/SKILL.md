---
name: interrogatorio-advpl
description: Use when user wants to stress-test a Protheus customization plan, validate design decisions for ADVPL/TLPP development, or mentions "interrogatorio", "interroga", "grill", "questiona", "valida o plano", "stress-test do plano".
---

Interrogue-me implacavelmente sobre cada aspecto deste plano de customizacao Protheus ate chegarmos a um entendimento compartilhado. Mapeie o plano como uma **arvore de design**: cada decisao ramifica nas decisoes que dependem dela.

Trabalhe a arvore em **rounds por fronteira**. A fronteira e toda decisao cujos pre-requisitos ja estao resolvidos — as perguntas que da para fazer AGORA sem chutar respostas que ainda nao vieram. Pergunte a fronteira inteira numa rodada, cada pergunta numerada no formato:

```
❓ **Q1** - **<titulo>**: <corpo da pergunta, com alternativas quando couber>

➡️ <sua resposta recomendada>
```

Cada rodada de respostas reforma a arvore: decisoes fechadas empurram a fronteira e desbloqueiam as perguntas que dependiam delas — recompute e pergunte a proxima rodada. Pergunta que depende de outra ainda aberta NESTA rodada pertence a rodada seguinte.

Fatos sao trabalho seu, nunca do usuario: pergunta da fronteira que depende de fato do ambiente (codebase, dicionario, TDN) → explore voce mesmo ou despache um subagente, sem bloquear a rodada — so as perguntas downstream esperam o resultado; o resto da fronteira e perguntado ja. As DECISOES sao do usuario.

A sessao termina quando a fronteira esvazia: todo ramo visitado, nada assumido em silencio.

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
