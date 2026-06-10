---
name: apontamento-gerar
description: Gera apontamento de trabalho para o cliente. Invocada via /apontamento-gerar.
disable-model-invocation: true
---

# Apontamento Gerar

Cria apontamentos de trabalho que serao lidos pelo cliente: linguagem acessivel mas precisa, mencionando modulo/rotina/tabela apenas quando agrega valor ao entendimento. O texto gerado e rascunho intermediario que o usuario cola no campo `note` da OS no tspace.

## Local do registro

Sempre `.apontamentos.md` no **diretorio de trabalho atual** (cwd). Um arquivo por projeto/cliente.

## Formato do registro

Texto puro (NAO markdown — o tspace nao renderiza). Apontamentos separados por linha em branco. Sem headers, sem datas, sem metadata — apenas o texto corrido na ordem cronologica (mais antigo no topo, novo no fim).

Exemplo de conteudo do arquivo:

```
Ticket: 00011835. Adicionado botao "Atualizar Estruturas" no MenuDef do cadastro MVC existente da ZB3 (TEC10A03). A rotina TEC10UpdEst busca todos os produtos com mesma Ferramenta + Cor do registro selecionado e atualiza suas estruturas (SG1) e roteiros (SG2) com base no produto padrao definido em ZB3_ESTPAD.

Ticket: 00011835. Criados pontos de entrada MT010INC e MT010ALT que executam apos inclusao e alteracao de produtos no MATA010. Ao salvar um produto tipo PA com Ferramenta e Cor preenchidos, busca na ZB3 se existe produto padrao para a combinacao. Se existir, pergunta ao usuario se deseja gerar ou atualizar estrutura e roteiro automaticamente, reaproveitando as funcoes compartilhadas T10CalcFat, T10UpdEst e T10UpdRot do TEC10G01.

alteracao tela de consulta de produtos para que feche ao apertar ESC

Implementacao da grade interativa para selecao multipla de produtos e configuracao dos mecanismos de busca rapida (por codigo, descricao e tipo) na tela de selecao.
```

## Voz e tom

**Particípio passado impessoal** — voz dominante no corpus real:

- Criada / Criado / Criação
- Implementada / Implementado
- Adicionado / Adicionada
- Customizado
- Reformulada / Ajustada / Otimização
- Corrigido / Corrige
- Realizados testes / Validados
- Feita análise / Verificado

Evitar voz ativa em primeira pessoa ("Eu fiz", "Implementei", "Refatorei") — soa como diario, nao como apontamento.

**Variante saudacao** — usar APENAS em projetos de atendimento eventual com ticket aberto pelo cliente:

```
Bom dia, referente ao ticket 00009481. Desenvolvimento finalizado, agora uma validacao foi adicionada caso nao seja inserido centro de custo na solicitacao de compra...
```

NAO usar saudacao em projetos de consultoria continua/mensal.

## Tamanho × horas (referência empírica)

| Horas    | Tamanho típico                       |
|----------|--------------------------------------|
| 0h30     | 1 frase / 4–10 palavras              |
| 1–2h     | 1 frase OU 1 parágrafo curto         |
| 4–6h     | 1 parágrafo (3–10 linhas)            |
| 7–8h     | 1 parágrafo denso OU 2–3 parágrafos  |
| 8h+      | texto longo (até ~250 palavras)      |

Nao e regra rigida — apontamento de 9h pode ser 1 linha se o trabalho foi simples (ex: `Corrige fonte SMT04M02T que estava importando da tabela incorreta as etiquetas`). Mas a tendencia e diretamente proporcional. Se o trabalho foi denso, redija denso; se foi simples, nao infle.

## Gêneros e estrutura típica

Antes de redigir, classifique a frente em um dos generos abaixo e aplique a estrutura indicada. A maioria dos apontamentos do corpus se encaixa em um destes 8.

### A. Implementação / criação
**Verbos:** Criada, Implementada, Adicionado, Customizado.
**Estrutura:** `[verbo + nome técnico]. [Como o usuário/operador usa]. [O que acontece tecnicamente ao salvar/executar]. [Tratamento defensivo OU cenários cobertos]. [Detalhe operacional final (parâmetro/log/etiqueta)].`

### B. Validação / testes
**Verbos:** Realizados testes, Validados.
**Estrutura:** `Realizados testes funcionais da rotina X validando [fluxo principal]. Tambem validados [cenarios extras: bloqueios, atalhos, comportamentos de borda]. [Resultado/confirmacao].`

### C. Levantamento / análise (planning)
**Verbos:** Levantamento, Mapeada, Definido escopo, Tomado como referência.
**Estrutura:** `Levantamento e validação de [escopo]. Mapeada a relação de [tabelas/campos/rotinas]. Definido escopo restrito a [X]. Definida apresentação em [forma]. Tomado como referencia [funcao analoga ja em producao].`

### D. Otimização / ajuste com efeito mensurável
**Verbos:** Otimização, Reformulada, Ajustado, Corrigida.
**Estrutura:** `Otimização da rotina X após [contexto]. Reformulada [parte], substituindo [comportamento antigo] por [comportamento novo], antes [problema perceptível], agora [resultado perceptível]. Ajustado [Y]. Validação final feita com [como confirmou].`
**Marca registrada:** o "antes X / agora Y" — descreve o efeito perceptível para o cliente, nao so a mudanca tecnica.

### E. Investigação / diagnóstico (cronologia)
**Verbos:** Feita análise, Verificado, A investigação identificou, A leitura apontou.
**Estrutura:** parágrafos cronológicos do raciocinio investigativo, separados por `\n\n` para criar respiro visual: sintoma → analise de log → identificacao da causa → verificacao com cliente → acao corretiva → confirmacao do estado.
**Fecho típico:** "Ambiente estabilizado.", "Problema resolvido."

### F. Bug fix curto
**Verbos:** Corrigido, Corrige.
**Estrutura:** 1 linha: `Corrigido fonte X que fazia Y errado.`

### G. Atendimento de ticket simples (saudação)
Apenas em atendimento eventual.
**Estrutura:** `[saudacao opcional], referente ao ticket NNNNN. Foi verificado que [problema]. [O que foi feito]. [Confirmacao].`

### H. Setup / preparação
**Estrutura:** 1 linha objetiva: `Adaptacao da base local para testes e criacao da classe inicial.`

## Nomenclatura técnica (citar / não citar)

### SEMPRE cita
Se o cliente pode achar no Configurador, Customizador ou na tela do sistema, vale citar:
- Fonte: `U_LST04R01`, `nfseXmlNac.prw`, `SMT04M02T`, `ASC08A01.prw`
- Rotina padrao Protheus: `MATA010`, `MATA650`, `MATA681`, `MATA103`, `MATA140`
- Tabela: `F2D`, `CJ3`, `SD1`, `SG1`, `ZB3`, `ZZ2`, `SX3`
- Campo: `C5_DESCRPS`, `D1_IDTRIB`, `G2_LOTEPAD`, `ZB3_ESTPAD`
- Parametro: `MV_TECG304`, `TEC_10004`, `MV_PAR01`
- Ponto de entrada: `MA650EMP`, `MT010INC`, `MT010ALT`
- Centro de trabalho / grupo de produto quando relevante: `CT 304`, `PE909`

### NUNCA cita
Detalhes que so um implementador entende e que nao mudam o que o cliente percebe:
- Funcoes de acesso a dado: `RecLock`, `DbSelectArea`, `DbSeek`, `MsSeek`, `MsUnLock`, `MsExecAuto`
- Variaveis/arrays internos: `aHeader`, `aCols`, `oModel`, `aArea`
- Estruturas de controle: `While`, `For`, `Do Case`
- Refatoracoes sem efeito visivel ("renomeei a variavel", "extrai funcao auxiliar")

## Ticket: prefixar ou omitir

**Padrao:** `Ticket: NNNNN. ` no inicio (com dois pontos, ponto e espaco).

**Omitir** quando:
- Consultoria mensal sem rastreamento por chamado (ex: LEISTUNG, MOLDEMAQ)
- Manutencao de fonte sem ticket aberto (ex: SMARTECH com ajuste pontual)
- Atividade interna curta (`Verificacao servidores`, `Adaptacao da base local`)

Quando em duvida, perguntar.

## Fechos típicos (apontamentos longos)

| Fecho                                                | Quando usar                              |
|------------------------------------------------------|------------------------------------------|
| `patch aplicado em producao`                         | Mudanca ja em producao                   |
| `testado em ambiente dev pelo cliente`               | Cliente ja validou em DEV/HML            |
| `Ambiente estabilizado.`                             | Investigacao resolvida                   |
| `Problema resolvido.`                                | Suporte fechado                          |
| `Validacao final feita com conferencia direta...`    | Quando ha prova de validacao             |
| `Tomado como referencia [rotina ja em producao]`     | Implementacao que segue padrao existente |

## Subtítulo curto (description tspace)

Cada apontamento no tspace tem dois campos: `note` (corpo) e `description` (subtitulo de ~30–40 chars que aparece na lista da agenda). Junto com o corpo, gere o subtitulo curto.

**Exemplos do corpus:**
- corpo "Criada rotina U_ApontaMoinho..." → subtitulo `Apont. Moinho/misturador`
- corpo "Otimizacao da rotina Possibilidade de Producao..." → subtitulo `fixes rel. poss. de producao`
- corpo "Realizados testes funcionais... balanca moinho" → subtitulo `Balanca Moinho`

## Processo

### Passo 1: Localizar/criar registro

Verifique se existe `.apontamentos.md` no diretorio atual.
- Se existir: leia o conteudo para entender de onde parou e o tom usado.
- Se nao existir: criara apos primeira aprovacao.

### Passo 2: Levantar o que foi feito desde o último

Use:
- A conversa atual (decisoes tomadas, arquivos modificados, problemas resolvidos)
- `git diff` e `git log --oneline` se for repositorio git
- Os ultimos apontamentos do registro como referencia do "ponto de partida"

Filtre: tentativas abandonadas, exploracao, perguntas — nao entram. Apenas o que efetivamente foi entregue.

### Passo 3: Perguntar sobre ticket

Antes de redigir, pergunte:

> **Tem ticket(s) associado(s) a este trabalho? (numero, "nao" ou "consultoria mensal sem ticket")**

Se houver multiplos apontamentos com tickets diferentes, pergunte por cada frente.

### Passo 4: Classificar gênero

Para cada frente, identifique o genero (A–H acima). Isso determina o verbo de abertura e a estrutura interna.

### Passo 5: Redigir corpo + subtítulo

Para cada frente:
1. Aplique a estrutura do genero.
2. Use particípio passado impessoal.
3. Cite nomenclatura tecnica conforme regras (SEMPRE / NUNCA).
4. Dimensione o tamanho conforme as horas (tabela de referencia).
5. Adicione fecho se for apontamento longo.
6. Gere o subtitulo curto (30–40 chars).

### Passo 6: Aprovação individual

Para CADA apontamento, mostre o corpo + subtitulo:

```
Apontamento [N de M] (genero: [A-H], ~Xh)

Subtítulo: [30-40 chars]

[corpo do apontamento]
```

E pergunte:

> **Aprovar, editar ou descartar?**

- Se editar: ajuste e mostre de novo ate aprovar.
- Se aprovar: marque para gravacao.
- Se descartar: pule.

### Passo 7: Gravar e exibir

Apos todas aprovacoes:

1. Anexe os corpos aprovados ao fim de `.apontamentos.md` (criando o arquivo se nao existir), separados por linha em branco. NAO grave os subtitulos no arquivo — eles ficam so no output da conversa para o usuario copiar manualmente para o tspace.
2. Exiba para copiar:

> **Gravado em `.apontamentos.md`. Para colar no tspace:**
>
> Apontamento 1 — Subtítulo: [...]
> ```
> [corpo]
> ```
>
> Apontamento 2 — Subtítulo: [...]
> ```
> [corpo]
> ```

## Finalização do trabalho (limpeza)

Se o usuario disser que vai **mandar fonte para producao**, **finalizar trabalho**, **encerrar projeto**, ou frase equivalente:

1. Confirme: "Vou apagar `.apontamentos.md` deste projeto. Confirma?"
2. Se confirmado, delete o arquivo.
3. Se nao confirmado, mantenha.

Esse comportamento NAO precisa ser invocado via `/apontamento-gerar` — observe o contexto da conversa.

## Múltiplos apontamentos numa única chamada

Se o usuario pedir explicitamente varios apontamentos (ex: "cria 3 apontamentos separando por frente"), gere todos antes de iniciar a aprovacao individual.
