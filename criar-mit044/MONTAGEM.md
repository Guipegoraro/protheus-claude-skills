# Montagem do DOCX

Referência dos passos 4 e 6 da [`SKILL.md`](SKILL.md). O gerador monta o documento sobre o
template oficial TOTVS embutido em `assets/` (capa, histórico, sumário, cabeçalho/rodapé, cinco
seções numeradas, aceite), clonando parágrafos e tabelas-protótipo de `assets/prototipos.xml`.
Ele limpa os textos de orientação `<...>` e placeholders `{{campo}}` do template e corrige o
campo do sumário (o original seleciona por nome de estilo em inglês e não monta nada no Word em
português).

## Comandos

```bash
python ~/.claude/skills/criar-mit044/scripts/gera_mit044.py <mit-conteudo.json> --saida "<pasta do plano>"
python ~/.claude/skills/criar-mit044/scripts/valida_mit044.py "<gerado.docx>" [--ref "<mit044-aprovada.docx>"]
```

Nome do arquivo gerado: `[<tag_cliente>] - Especificação da Customização - MIT044 - <titulo>.docx`.
Caminhos relativos de figura resolvem a partir da pasta do JSON.

Opções do gerador: `--force` sobrescreve (salva `.bak` antes) · `--template` usa outro
esqueleto · `--numeracao-uniforme` põe os cinco títulos na mesma lista numerada (quando a
numeração sai "a., b., 01., 02.") · `--sem-respiro` desliga as quebras de linha entre blocos.

O validador faz 21 verificações estruturais (esqueleto de títulos, tabelas obrigatórias, capa
sem rótulo órfão, uma forma de execução marcada, labels em negrito, fluxo numerado, sem sobras
do template, sumário por nível, cabeçalho/rodapé e fontes preservados, sem travessão no corpo);
com `--ref`, compara esqueleto, número e estilos de tabela com uma MIT044 aprovada.

## Esquema do JSON

| Chave | Conteúdo |
|---|---|
| `arquivo.tag_cliente`, `arquivo.titulo` | montam o nome do arquivo |
| `capa.*` | `nome_cliente`, `codigo_cliente`, `nome_projeto`, `codigo_projeto`, `segmento_cliente`, `unidade_totvs`, `data`, `proposta_comercial`, `gerente_totvs`, `gerente_cliente`, `responsavel_totvs`, `responsavel_cliente`, `qtd_horas` |
| `capa.extra_projeto` | `sim` / `nao` / `""` (marca o checkbox) |
| `capa.criticidade` | `alto` / `medio` / `baixo` / `""` |
| `historico` | lista opcional de `{"data", "versao", "autor", "descricao"}`; omitida, gera `1.00` com a data e o responsável TOTVS da capa e "Emissão inicial do documento." |
| `processo_atual`, `processo_proposto`, `parametrizacoes` | lista de itens |
| `execucao` | `objetivos`, `fluxo`, `premissas`, `plano_teste` (listas de itens) e `rastreabilidade` (texto) |
| `customizacoes.periodicidade` | `sob_demanda` / `job` / `continua` (textos) + `marcada` (qual recebe o X) |
| `customizacoes.onde_executada` | `texto`, `rotina`, `menu` |
| `customizacoes.funcionalidades`, `premissas_tecnicas` | lista de itens (`RF01: ...;`) |
| `customizacoes.prototipo_tela` | texto ou lista de itens |
| `customizacoes.anexos` | lista de pares `["Descrição", "Observação"]` |

Os labels em negrito de cada bloco ("Objetivos do negócio:", "Anexos:"...) são escritos pelo
gerador; não entram no JSON.

### Itens

Um item é uma string (parágrafo) ou um objeto:

| `tipo` | Campos | Resultado |
|---|---|---|
| `p` | `texto` | parágrafo narrativo |
| `bullet` | `texto` | `•  texto`, recuo de 1 cm |
| `num` | `texto` | `N.  texto`, numerado na ordem dentro do bloco |
| `label` | `texto` | rótulo em negrito |
| `imagem` | `src`, `legenda`, `largura_cm` (padrão 16, máximo 17,5) | figura centralizada + legenda em itálico 9pt cinza |
| `tabela` | `linhas` (lista de listas; a primeira é o cabeçalho) | tabela de N colunas no estilo da tabela de Anexos, larguras iguais |

`imagem` e `tabela` podem aparecer em qualquer lista de itens; dentro de `execucao.fluxo` não
consomem número de passo.

## Erros comuns

| Sintoma | Causa | Correção |
|---|---|---|
| `arquivo já existe` | proteção contra sobrescrita | `--force` (gera `.bak`) ou mudar o título |
| `FileNotFoundError` em nome com acento | nome em Unicode NFD (acentos decompostos) | localizar por substring sem acento: `[f for f in os.listdir(D) if 'MIT044' in f]` |
| `seção obrigatória ausente no JSON` | falta uma das 7 chaves de topo | o gerador aborta antes de gravar; completar o JSON |
| `imagem não encontrada` | caminho relativo à pasta errada | caminhos resolvem a partir da pasta do JSON |
| Acentos corrompidos no terminal | console cp1252 | os scripts forçam UTF-8; redirecionar para arquivo só com `-Encoding utf8` |

## Outro template

Para cliente com identidade visual própria, ou para adotar ajustes de diagramação feitos à mão
no Word, regenerar os assets a partir de uma MIT044 aprovada daquele cliente:

```bash
python ~/.claude/skills/criar-mit044/scripts/extrai_template.py "<mit044-aprovada.docx>" "<pasta de destino>"
```

Ele extrai os protótipos (parágrafo narrativo, label em negrito, bullet e as três tabelas de
conteúdo), esvazia o miolo entre "Processo Atual" e "Aceite" preservando os cinco `Heading 2`,
limpa a capa e o histórico mantendo os rótulos, e grava `template-mit044.docx` +
`prototipos.xml`. Ele imprime quais parágrafos escolheu; escolha ruim se corrige apontando
outro por prefixo (`--proto-body "O processo de"`). Gerar em pasta temporária, conferir a saída
do script e só então substituir `assets/`, ou passar a pasta em `--template`. Preferir a MIT044
mais recente e visualmente correta: documentos antigos com id de estilo `normal` em minúsculas
quebram como doadores de formatação.
