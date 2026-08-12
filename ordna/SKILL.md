---
name: ordna
description: Use when a directory holds .ordna/ or tasks/*.md, or the user names ordna, the board, or a card — reading the board, creating or editing tasks, moving cards between columns.
---

# Ordna

Board derivado de arquivos: cada task é um markdown em `tasks/`, cada coluna é um valor de `status`. Não existe estado de board em lugar nenhum — o arquivo é a fonte de verdade e o Kanban é **projeção**. O CLI `ordna` valida status e dependência por cima desses mesmos arquivos.

## Granularidade

Leia na menor granularidade que responde à pergunta — no mesmo board, abrir os arquivos custa mais de uma ordem de grandeza a mais que listar.

| Pergunta | Como responder |
|---|---|
| O que existe / o que está pendente | `ordna ls`, `ordna ls -s <status>` |
| O que essa task diz | `ordna show <id>` |
| Vou **editar** o corpo | Read + Edit em `tasks/<id>.md` |

`ordna ls` e `ordna show` respondem no terminal. A TUI (`ordna`, `ordna board`) é interativa — quem abre é o usuário.

## Storage

`.ordna/config.yaml` pode trazer `storage: file` (padrão) | `hybrid` | `namespace`. Nos dois primeiros as tasks são arquivos em `tasks/`. Em **`namespace` não existe arquivo** — as tasks vivem em `refs/ordna/tasks/<id>` e tudo passa pelo CLI. Confirme o modo antes de abrir arquivo.

## Ciclo de uma task

1. `ordna create "<título>"` cria com o esqueleto (`## Goal`, `## Acceptance Criteria`, `## Notes`, `## Progress`). Flags: `-p high|medium|low`, `-t <tag...>`, `-d <dependência...>`, `-s <status>`, `-a <nome>`. O comando aceita só o título — o corpo detalhado você escreve editando `tasks/<id>.md`.
2. Executa.
3. Registra em `## Progress` o que foi feito, marca os checkboxes de `## Acceptance Criteria` que passaram, e põe `updated_at` na data de hoje.
4. `ordna move <id> <status>`.

Passo 3 antes do 4, sempre: task fechada sem Progress não conta como feita.

`ordna commit -m "msg"` faz `git add tasks/` + commit, e roda quando o usuário pede.

O resto do CLI (`assign`, `web`, `attach`, filtros de `ls`) sai de `ordna --help` e `ordna <cmd> --help`.

## Colunas e dependências

Padrão `todo → doing → done`. `statuses:` no config redefine as colunas na ordem, e a primeira é o default de tasks novas.

- O **último status da lista é o terminal**. Mover pra ele com `depends_on` em aberto é rejeitado pelo CLI.
- `archived` é reservado — sempre aceito, e filtrado das demais visões.

## Qual board

Um board por diretório: o `ordna` lê `<cwd>/.ordna/config.yaml`, e não existe flag `--cwd`. Boards são independentes entre si — IDs, colunas e contadores próprios. Quando o cwd não for o board que o usuário quer, pergunte antes de criar.

## Referência

Frontmatter campo a campo, compatibilidade Backlog.md, todas as chaves de config, storage em detalhe: `reference.md`, nesta pasta.
