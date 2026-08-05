# Pesquisa: [Nome da Feature]

**Data:** [DATA]
**Cliente:** [NOME] | **Modulo:** [MODULO]

---

## Rotinas Padrao Envolvidas
| Rotina | Descricao | Relevancia |
|--------|-----------|-----------|
| MATA010 | Cadastro de Produtos | Sera consultada para... |

## Tabelas
| Alias | Descricao | Uso | Campos-chave |
|-------|-----------|-----|-------------|
| SA1 | Clientes | Leitura | A1_COD, A1_LOJA |
| ZXX | [Custom] | Gravacao | ZXX_COD |

## Pontos de Entrada
| PE | Rotina | Descricao | Relevante porque |
|----|--------|-----------|-----------------|
| MT010INC | MATA010 | Inclusao de produto | Podemos usar para... |

## Parametros MV
| Parametro | Descricao | Valor padrao | Impacto |
|-----------|-----------|-------------|---------|
| MV_EXEMPLO | Descricao | .T. | Afeta... |

## Funcoes do Framework
| Funcao/Metodo | Uso planejado |
|---------------|--------------|
| FWFormModel | Base do cadastro MVC |

## Validacao TDN
| Funcao/Metodo | Parametros | Retorno | Status TDN |
|---------------|------------|---------|------------|
| MsExecAuto | ... | Logico | Documentado |
| FWFormModel | ... | Objeto | Sem doc TDN — ref: skill mvc-generator |

## Dicionario de Dados
### SA1 — Clientes
| Campo | Tipo | Tam | Descricao |
|-------|------|-----|-----------|
| A1_COD | C | 6 | Codigo do cliente |
| A1_LOJA | C | 2 | Loja |

**Indices disponiveis:** A1_COD+A1_LOJA (unico), ...

## Customizacoes Existentes no Cliente
| Fonte | Descricao | Relacao com esta feature |
|-------|-----------|------------------------|
| BRNCUST01.prw | Customizacao de PCP | Sera modificado para... |

## Integracoes
| Sistema/Modulo | Tipo | Descricao |
|---------------|------|-----------|
| Fiscal (SIGAFIS) | Trigger | Geracao de nota ao... |

## Notas e Descobertas
- [Anotacoes livres sobre o que foi descoberto durante a pesquisa]
