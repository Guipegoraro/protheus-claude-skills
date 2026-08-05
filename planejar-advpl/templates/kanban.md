# Kanban: [Nome da Feature]

**Ultima atualizacao:** [DATA]

## Camadas e gates

Ordem bottom-up (ex: parsers -> analise -> motor -> telas -> integracao). Camada so FECHA com testes verdes + gate aprovado; camada seguinte NAO inicia com gate aberto. Gate reprovado -> bug vira teste que reproduz (template fixes/, ver bug-spec) -> re-gate.

| Camada | Tasks | Evidencia que fecha | Gate | Status |
|--------|-------|---------------------|------|--------|
| 1 - [nome] | TASK-001..004 | maquina (testes verdes) | evidencia local | aberto |
| 2 - [nome] | TASK-005..008 | maquina + humano | usuario roda no TST | aberto |

- **Evidencia de maquina** fecha camadas baixas (logica pura, parsers, calculos). **Gate humano** e obrigatorio em camada que toca carteira/fiscal/faturamento — a IA nao tem acesso ao ambiente do cliente.
- A ULTIMA task de cada camada entrega o ROTEIRO do gate humano: script do que o usuario executa e confere — nunca "cliquei e pareceu ok".
- Revisao adversarial recorrente: rodada numerada + achados contados (a) no plano/kanban antes de executar, (b) ao fim de CADA camada sobre o fonte, (c) antes do deploy. Adversarial que nao acha mais nada = artefato maduro.
- Spike sem data mas no caminho critico: EXPLICITO como task propria, senao bloqueia a camada em silencio.

---

## TODO

### TASK-001: [Titulo descritivo]
- **Descricao**: O que fazer
- **Arquivos**: `path/to/file.prw`, `path/to/file2.tlpp`
- **Complexidade**: Baixa | Media | Alta
- **Dependencias**: Nenhuma | TASK-XXX
- **Camada**: N
- **Regras**: RN-xx, CB-xx (casos-e-regras.md)
- **Criterio de aceite**: O que define "pronto" — SEMPRE inclui o teste correspondente (task sem teste nao fecha; kanban sem esse contrato vira lista de intencoes)

### TASK-002: [Titulo descritivo]
...

---

## DOING

(vazio no inicio)

---

## DONE

(vazio no inicio)

<!-- Formato ao concluir uma task (mover para DONE):

### TASK-001: [Titulo] ✓
- **O que foi feito**: Resumo do que foi implementado
- **Arquivos modificados**: Lista final dos arquivos tocados
- **Observacoes**: Qualquer nota relevante
-->
