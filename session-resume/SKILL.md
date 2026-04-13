---
name: session-resume
description: Recarrega o resumo de sessao gerado por /session-summary apos um /clear. Restaura contexto denso do projeto para continuar o trabalho sem perda de informacao.
argument-hint: [nome-do-resumo]
disable-model-invocation: true
---

# Session Resume

Recarrega o contexto de uma sessao anterior salvo por `/session-summary`.

## Processo

### Passo 1: Localizar o resumo

Se `$ARGUMENTS` foi fornecido, procure `.claude/session-resume-$ARGUMENTS.md`.
Senao, procure `.claude/session-resume.md`.

Se o arquivo nao existir, informe:

> **Nenhum resumo encontrado.** Rode `/session-summary` antes de `/clear` para gerar um.

### Passo 2: Ler e apresentar

1. Leia o arquivo completo
2. Apresente um resumo curto ao usuario:

> **Sessao restaurada: [nome do trabalho]**
> - **Objetivo**: [objetivo]
> - **Arquivos**: [quantidade] arquivos trabalhados
> - **Pendencias**: [quantidade] tarefas pendentes
>
> Contexto completo carregado. Pode continuar de onde parou.

3. Internalize TODO o conteudo do arquivo — decisoes, padroes, gotchas, estado dos arquivos. A partir daqui, trabalhe como se tivesse participado da sessao anterior.

### Passo 3: Oferecer limpeza

Apos apresentar o resumo, pergunte:

> **Deseja excluir o arquivo de resumo?**
> 1. **Manter** — o arquivo fica disponivel para futuras referencias
> 2. **Excluir** — removo `.claude/session-resume.md` para manter o diretorio limpo

Se o usuario escolher excluir, delete o arquivo e confirme.

### Passo 4: Continuar

Aguarde instrucoes do usuario. Voce agora tem o contexto completo para continuar o trabalho.
