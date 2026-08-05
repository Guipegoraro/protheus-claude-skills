# Template: casos-e-regras.md (canone de regra de negocio)

Regra de negocio VIVE aqui e em NENHUM outro lugar — os demais docs (arquitetura, dominio, PRD, kanban, MIT) CITAM o ID, nunca reescrevem o texto. Doc que precisa da regra aponta; quem reescreve cria a segunda verdade que diverge da primeira.

**IDs:** `RN-xx` = regra de negocio · `CB-xx` = caso de borda. Citados em fonte (comentario), kanban, QA e commit interno — "por que este codigo existe" sempre tem resposta.

---

```markdown
# Casos e Regras — <slug>

> Canone unico. Outros docs citam o ID. Conflito entre docs: vale o mais recente, e o conflito e REGISTRADO aqui, nao sobrescrito.

## Regras de negocio

### RN-01 — <titulo curto>
- **Regra:** <texto normativo completo>
- **Fonte:** <e-mail/reuniao/ticket, data, quem> (obrigatoria — sem fonte a regra nao entra aqui; vai para perguntas-cliente.md)
- **Implementada em:** <fonte.tlpp:funcao> (preencher na implementacao)

## Casos de borda

### CB-01 — <titulo curto>
- **Cenario:** <quando acontece>
- **Comportamento esperado:** <o que o sistema faz>
- **Fonte:** <ou "decisao interna + aviso" se for fallback permissivo>
- **Coberto por teste:** <suite/teste> (preencher)
```

---

## Passada regra -> codigo (rodar no QA e antes do deploy)

O sentido codigo -> regra acha codigo sem regra. O sentido INVERSO acha regra que o codigo contradiz — e comentario convicto e defeito sao indistinguiveis na leitura do fonte (ja houve Protheus.doc documentando com seguranca exatamente o comportamento contrario a RN com fonte do cliente). Por isso, periodicamente:

1. Para CADA RN/CB da tabela: onde esta implementada? O comportamento do codigo BATE com o texto da regra?
2. Divergencia => confronto fonte-do-cliente x comportamento; corrigir o codigo (ou, se a fonte mudou, atualizar a regra COM a nova fonte e registrar o conflito).
3. RN sem "Implementada em" preenchido ao fim da implementacao = pendencia de rastreabilidade.
