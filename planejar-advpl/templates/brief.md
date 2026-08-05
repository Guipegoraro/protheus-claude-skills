# Template: brief de task (auto-contido)

Brief e o documento que um agente implementador recebe para executar UMA task do kanban. O agente NAO ve a conversa nem o historico da sessao — ele carrega CLAUDE.md, MCPs e skills do projeto, e nada mais. Por isso:

**Regras de construcao (load-bearing):**
1. **Todo contexto entra por caminho de arquivo ou texto integral colado.** "Conforme decidimos" / "como discutido acima" e proibido — para o agente, isso e null.
2. **A fonte e normativa; o brief e derivado.** O brief manda o agente CONFERIR a fonte citada antes de copiar dela — e seguir a FONTE quando divergirem (erro de transcricao do planejador nao pode virar codigo).
3. **Comando de shell citado em doc verificado se COPIA literalmente** — nunca se reescreve de memoria (um comando testado reescrito vira um comando novo e nao testado).
4. **Brief > ~1 pagina = a task esta gorda.** Quebrar a task ANTES de emitir, nao depois de falhar.
5. **Contrato de heranca fixa o gancho explicitamente** (metodo publico com as guardas + metodo protegido que a subclasse sobrescreve). "Delega ao gancho" sem assinatura = drift garantido.
6. Task que exige testar caminho dependente de parametro ou estado caro: o brief manda criar a COSTURA junto (gancho protegido + subclasse sintetica), senao o agente entrega codigo correto e nao-testavel.

---

```markdown
# TASK-NNN: <titulo>

## Objetivo
<1-3 frases: o que existe ao final que nao existia antes>

## Contrato
<assinaturas completas: classe/metodo/funcao, parametros com tipo, retorno.
Heranca: metodo publico guarda + metodo protected gancho, com assinatura dos DOIS.>

## Regras aplicaveis (texto INTEGRAL, nao so o ID)
- RN-xx: "<texto completo da regra>" (fonte: casos-e-regras.md)
- CB-xx: "<texto completo do caso de borda>"

## Testes exigidos
<lista dos testes que DEVEM existir e passar; nome da suite/arquivo;
se o caminho depende de parametro/estado: instrucao da costura (gancho + subclasse sintetica)>

## Ciclo
Testes primeiro -> implementar -> placar verde COLADO na entrega.
Niveis de evidencia: declarar o que foi executado (syntax check / compilou / RODOU).
Entrega sem execucao = marcar "NAO-EXECUTADO" explicitamente.

## Dados
<codigos de erro PRE-ATRIBUIDOS para esta task (do catalogo central .ch) — o agente nunca inventa codigo;
massa de teste: caminho dos arquivos/goldens>

## Toolchain (comandos prontos — copiar, nao adaptar)
<compilar: comando exato; executar teste: comando exato; fallback se a via principal falhar.
Tools MCP com nome qualificado: file-tools:read_text_file (cp1252), tds:tds_compile, etc.>

## Fontes (conferir ANTES de copiar; a fonte vence o brief)
- <caminho 1> — <o que contem>
- <caminho 2> — <o que contem>

## Fora de escopo
<o que esta task NAO faz; arquivos que sao territorio de outras tasks paralelas>

## Cadeia de verificacao de conhecimento
Ordem: codebase -> docs do projeto (.claude/plans/<slug>/) -> MCPs -> web -> declarar incerteza.
NUNCA fabricar nome de campo/funcao/parametro — na duvida, declarar a duvida na entrega.
```
