# Template: bug-spec (correcao dirigida por especificacao)

Para bugs achados apos o kanban montado (gate reprovado, QA, producao). O artefato que dirige a correcao responde "O QUE esta errado x esperado" — a CAUSA RAIZ e achado de plano/investigacao, nao parte da spec. Criar em `.claude/plans/<slug>/fixes/NNN-<slug-curto>.md`.

---

```markdown
# FIX-NNN: <titulo>

## Comportamento errado x esperado
- **QUANDO** <condicao/entrada concreta>
- **ENTAO deveria** <comportamento esperado, testavel>
- **MAS ocorre** <comportamento observado>
- **Regra ferida:** RN-xx / CB-xx (se houver; senao, registrar a regra nova em casos-e-regras.md primeiro)

## Reproducao deterministica
<passos exatos / massa / comando que reproduz — se nao ha repro deterministica, a task ANTES desta e construi-la (skill diagnosing-bugs, Fase 1)>

## O que NAO mexer
<arquivos/funcoes vizinhas fora do escopo desta correcao — protege contra "consertei e quebrei o vizinho">

## Aceite
- [ ] Teste que reproduz o bug escrito ANTES do fix e agora passa
- [ ] NAO-REGRESSAO: bateria dos vizinhos listados acima roda verde (bateria inteira, nao so o caso X)
- [ ] Causa raiz registrada (1 paragrafo) na entrega — e "o que teria prevenido" avaliado
```
