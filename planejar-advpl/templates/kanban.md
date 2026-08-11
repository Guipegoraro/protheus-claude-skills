# Kanban: [Nome da Feature]

<!-- Fallback: use este arquivo so quando a maquina nao tem kanban provider. Regras de camadas/gates, contrato do card e movimentacao estao em ETAPA-5-KANBAN.md. -->

**Ultima atualizacao:** [DATA]

## Camadas e gates

| Camada | Tasks | Evidencia que fecha | Gate | Status |
|--------|-------|---------------------|------|--------|
| 1 - [nome] | TASK-001..004 | maquina (testes verdes) | evidencia local | aberto |
| 2 - [nome] | TASK-005..008 | maquina + humano | usuario roda no TST | aberto |

---

## TODO

### TASK-001: [Titulo descritivo]
- **Descricao**: O que fazer
- **Origem**: [requisito do PRD] / [E-n do escopo declarado] — card sem origem nao entra no kanban
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
