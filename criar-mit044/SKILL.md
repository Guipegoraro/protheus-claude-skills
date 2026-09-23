---
name: criar-mit044
description: Redige a MIT044 (especificação de customização Protheus que o cliente assina) a partir de um plano fechado e monta o DOCX no modelo oficial.
disable-model-invocation: true
---

# Criar MIT044

Transcreve um planejamento fechado (mapa wayfinder, plano ou PRD) no documento de especificação
que o cliente assina. A MIT nunca decide nada novo: item sem decisão vira premissa permissiva
("definido na implantação") ou entra nas Restrições como fora de escopo.

O leitor é o gestor do cliente, não o dev. Tudo que o documento afirma precisa ter fonte
(decisão registrada, resposta do cliente, definição da implantação).

A fonte editável do documento é `mit-conteudo.json` na pasta do plano
(`.claude/plans/<slug>/`), com as figuras em `mit-figuras/` ao lado. O DOCX é gerado a partir
dele; revisão pedida pelo cliente é editar o JSON e gerar de novo, nunca retocar o DOCX.

## Passos

### 1. Coletar as fontes

- Decisões do plano: `.claude/plans/<slug>/` (mapa, glossário, pré-produção, perguntas)
- MIT044 anterior do mesmo projeto, se existir: reaproveitar dela os dados da capa em vez de
  perguntar de novo. Se o projeto usa layout próprio, regenerar o template a partir dela
  ([`MONTAGEM.md`](MONTAGEM.md), "Outro template")
- Corpus de exemplos: pasta `exemplos-mit/` se existir no projeto
- Guia de desenvolvimento do projeto: procurar em `.claude/` primeiro (versões na raiz do repo
  podem estar desatualizadas; confirmar com o dev qual vale)
- Protótipos de tela aprovados (HTML ou imagem), se houver

Completo quando cada seção do modelo tem fonte mapeada ou lacuna anotada para o passo 2.

### 2. Perguntar ao dev antes de redigir

Uma rodada só, em prosa: Qtd. Horas, Criticidade (Alto, Médio ou Baixo Impacto), Extra Projeto,
responsáveis, quem assina o Aceite, e qualquer lacuna do passo 1. Campo que o dev mandar deixar
em branco fica em branco.

### 3. Calibrar no corpus

Converter 1 ou 2 exemplos para imagem e ler todas as páginas (mecânica em
[`LEITURA.md`](LEITURA.md)). O objetivo é absorver o padrão da casa: tabelas com header azul
claro, subtítulos de seção em laranja, plano de teste, cenários de resultado, máquina de estados
quando há status, fluxograma por processo, Aceite com assinatura TAE quando aplicável.

### 4. Redigir o conteúdo

Antes de escrever, ler [`REDACAO.md`](REDACAO.md): voz, fórmula de abertura de cada seção,
blocos em ordem fixa e tamanho de referência.

Copiar [`exemplo-conteudo.json`](exemplo-conteudo.json) para `mit-conteudo.json` na pasta do
plano e substituir todo o conteúdo (o exemplo é fictício; nada dele sobrevive). O esquema do JSON
está em [`MONTAGEM.md`](MONTAGEM.md). Ordem do documento: capa (Ambientação), Histórico de
Versões, Dados da Customização (valores do passo 2), a. Processo Atual, b. Processo Proposto,
01. Parametrizações, 02. Execução, 03. Customizações (com protótipos como figuras e tabela de
Anexos), Aceite.

Regras de conteúdo, todas aplicadas em cada seção:

- **Linguagem do cliente.** Jargão técnico traduzido para português corrente: "allowlist" vira
  "lista do que é reconhecido como...", "stage" vira "tabela intermediária de importação",
  "idempotência" vira "reimportar não duplica". Termo técnico só quando o cliente o encontra na
  tela do sistema (rotina, campo, parâmetro).
- **Pontuação simples**: vírgula, dois-pontos, parênteses, hífen. Travessão e meia-risca dão ao
  texto cara de gerado por IA; o validador do passo 6 rejeita o documento que os tiver.
- **Exemplo não é fato assinável.** Nome de filial, pessoa ou valor citado como exemplo na
  conversa não entra no documento ("múltiplas filiais", nunca a lista de exemplo).
- **Menos partes móveis.** Revisar o desenho contra conveniência automática que não paga o
  custo (ex.: usuário seleciona a operadora na importação; o layout valida em vez de
  identificar). Sinalizar ao dev qualquer simplificação feita.
- **Escopo negativo explícito.** As Restrições nomeiam o que NÃO está contemplado; é o que
  protege o dev na assinatura. Carregar o Out of scope do plano.
- **Nomenclatura pelo guia do projeto.** Fontes, parâmetros e aliases de tabela seguem o guia
  de desenvolvimento; propor com nota "(a definir no desenvolvimento)", nunca batizar
  dicionário na MIT.
- **Pessoas só com nome confirmado**; senão "equipe de implantação" ou "definição do cliente
  de DD/MM/AAAA".

Completo quando cada decisão do plano aparece no JSON ou tem exclusão justificada.

### 5. Figuras

- Um fluxograma por processo ou momento, como primeiro item de `execucao.fluxo`, antes dos
  passos numerados. Spine vertical de nós, desvios de exceção como caixas laterais (vermelho
  rejeição, cinza ignorado, amarelo atenção). As mesmas regras de linguagem do passo 4 valem
  dentro dos nós.
- Protótipos entram preenchidos: acionar os botões de simulação antes de capturar, nunca
  capturar tela vazia. Vão em `customizacoes.prototipo_tela`, depois do parágrafo descritivo.
- Cada figura é um item `{"tipo": "imagem", ...}` com legenda "Figura N: ..."; numeração
  sequencial na ordem do documento, e referência cruzada na tabela de Anexos.

Desenho, captura e recorte em [`FIGURAS.md`](FIGURAS.md).

### 6. Montar o DOCX

Gerar com `scripts/gera_mit044.py` e conferir com `scripts/valida_mit044.py`
([`MONTAGEM.md`](MONTAGEM.md)). O DOCX vai para a pasta do plano, ao lado do JSON.

Completo quando o validador imprime `TUDO OK`.

### 7. Verificar antes de entregar

- Exportar PDF pelo Word (atualiza o sumário e salva o DOCX no caminho), renderizar TODAS as
  páginas em PNG e ler cada uma como imagem ([`LEITURA.md`](LEITURA.md)). Erros típicos:
  conteúdo na seção errada, legenda órfã, imagem estourando margem, tabela cortada na quebra de
  página, sumário com página errada.
- Papel A4 no PDF exportado (`pdfinfo`: "595 x 842 pts").
- Varrer o texto por jargão remanescente, inclusive dentro das figuras.

Completo quando todas as páginas foram lidas e as três checagens passaram.

### 8. Entregar e sincronizar

Enviar o DOCX ao dev, registrar no plano o estado do documento e qualquer decisão de desenho
tomada na redação (com adendo no ticket correspondente, quando houver mapa).
