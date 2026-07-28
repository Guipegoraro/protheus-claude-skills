# Examples

Concrete walk-throughs. Each one is the recipe you'd hand to a Protheus admin to apply via Configurador. Always document the same rows in `.claude/plans/<slug>/pre-producao.md`.

## 1. Create a custom table ZA0 — credit-limit history

**Purpose**: track historical credit-limit changes per customer.

**SX2 row**:

| Field | Value |
| --- | --- |
| X2_CHAVE | `ZA0` |
| X2_ARQUIVO | `ZA0010` (auto-derived) |
| X2_NOME | `Histórico de Limite de Crédito` |
| X2_NOMEENG | `Credit Limit History` |
| X2_NOMESPA | `Historial Límite de Crédito` |
| X2_MODO | `E` (per-branch) |
| X2_DISPLAY | `ZA0_FILIAL+ZA0_CLIENT+ZA0_LOJA+ZA0_DTALT` |
| X2_AUTREC | `1` (auto-RECNO) |
| X2_STAMP | `1` (audit timestamp) |
| X2_INSDT | `1` (insert timestamp) |
| X2_PROPRI | `U` (auto) |

**SX3 rows** (in order):

| Campo | Tipo | Tamanho | Decimal | Título | Picture | Contexto | Obrigat | Used | X3_F3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ZA0_FILIAL | C | 2 | 0 | Filial | `@!` | R | N | key | — |
| ZA0_CLIENT | C | 6 | 0 | Cliente | `@!` | R | S | yes | `SA1` |
| ZA0_LOJA | C | 2 | 0 | Loja | `@!` | R | S | yes | — |
| ZA0_DTALT | D | 8 | 0 | Data Alteração | — | R | S | yes | — |
| ZA0_VLANT | N | 14 | 2 | Valor Anterior | `@E 99,999,999.99` | R | N | yes | — |
| ZA0_VLNOV | N | 14 | 2 | Valor Novo | `@E 99,999,999.99` | R | S | yes | — |
| ZA0_USER | C | 6 | 0 | Usuário | `@!` | R | S | yes | — |
| ZA0_OBSERV | M | 0 | 0 | Observação | — | R | N | yes | — |

**Helps de campo** (F1 — required, one per field, self-contained end-user text):

| Campo | Help |
| --- | --- |
| ZA0_CLIENT | `Código do cliente cujo limite de crédito foi alterado. Pressione F3 para pesquisar o cadastro de clientes.` |
| ZA0_LOJA | `Loja do cliente. Junto com o código do cliente, identifica a unidade cujo limite foi alterado.` |
| ZA0_DTALT | `Data em que a alteração do limite de crédito foi efetivada no cadastro do cliente.` |
| ZA0_VLANT | `Valor do limite de crédito vigente antes desta alteração, em reais.` |
| ZA0_VLNOV | `Novo valor do limite de crédito atribuído ao cliente nesta alteração, em reais.` |
| ZA0_USER | `Código do usuário do sistema que efetuou a alteração do limite de crédito.` |
| ZA0_OBSERV | `Justificativa ou observações sobre a alteração do limite. Texto livre, opcional.` |

Notes:

- `ZA0_CLIENT` and `ZA0_LOJA` should carry `X3_GRPSXG` linking to the standard customer-code group (`031` or whatever SXG group SA1 uses on this environment). Verify via `FWSX3Util():GetAllGroupFields(cGrp)` before fixing the group code.
- `ZA0_CLIENT` gets `X3_F3 = "SA1"` for the F3 lookup.
- The help texts explain the field on their own — no ticket/PRD reference, no bare internal names.

**SIX rows**:

| Ordem | Chave | Descrição | Nickname | ShowPesq |
| --- | --- | --- | --- | --- |
| 1 | `ZA0_FILIAL+ZA0_CLIENT+ZA0_LOJA+DTOS(ZA0_DTALT)` | Por cliente + data | `ZA0CDT` | S |
| 2 | `ZA0_FILIAL+DTOS(ZA0_DTALT)` | Por data | `ZA0DT` | S |

Both indexes get nicknames so the code that uses them is independent of TOTVS reordering.

## 2. Add a field to a TOTVS table — A1_CREDLIM credit override

**Purpose**: a customer-level cap that overrides the operational rule.

**SX3 row** (insert):

| Field | Value |
| --- | --- |
| X3_ARQUIVO | `SA1` |
| X3_CAMPO | `A1_CREDLIM` |
| X3_TIPO | `N` |
| X3_TAMANHO | 14 |
| X3_DECIMAL | 2 |
| X3_TITULO | `Limite crédito` |
| X3_DESCRIC | `Limite de crédito por cliente, sobrepõe MV_ESCRDLIM` |
| X3_PICTURE | `@E 99,999,999.99` |
| X3_CONTEXT | R |
| X3_VALID | `Positivo() .OR. M->A1_CREDLIM == 0` |
| X3_USADO | yes (financeiro module) |
| X3_OBRIGAT | no |
| X3_BROWSE | S |
| X3_PROPRI | U (auto) |
| X3_FOLDER | folder where the cadastral fields live (often 1) |

**Help de campo** (F1):

```
Limite de crédito específico deste cliente, em reais. Quando preenchido com valor maior que zero, sobrepõe o limite de crédito padrão da empresa na análise de crédito dos pedidos de venda. Quando zero, o sistema usa o limite padrão configurado pelo administrador.
```

Note the help stands on its own — it explains the override behaviour in words instead of citing `MV_ESCRDLM` or the project documentation.

No SIX needed (existing SA1 indexes cover most queries; if the customer wants a "filter by credit limit" report, a new index can be added later).

The field survives UPDDISTR (it's customer-owned, `X3_PROPRI = U`).

## 3. Create a parameter — credit-limit default

**Purpose**: configurable default when `A1_CREDLIM` is zero.

**SX6 row**:

| Field | Value |
| --- | --- |
| X6_FIL | (blank — applies to all branches) |
| X6_VAR | `MV_ESCRDLM` |
| X6_TIPO | `N` |
| X6_DESCRIC | `Limite de crédito default` |
| X6_DESC1 | `quando A1_CREDLIM == 0,` |
| X6_DESC2 | `usado por U_VALCRED.` |
| X6_CONTEUD | `1000.00` |
| X6_PROPRI | U (auto) |

**Reader**:

```advpl
Local nDefault := SuperGetMV("MV_ESCRDLM", .F., 1000.00)
```

Always pass the third-arg default. The parameter may be absent right after a fresh deploy.

## 4. Per-branch parameter override

After example 3, the customer wants branch 02 to use a different default. Add a second SX6 row:

| X6_FIL | X6_VAR | X6_CONTEUD |
| --- | --- | --- |
| (blank) | `MV_ESCRDLM` | `1000.00` |
| `02` | `MV_ESCRDLM` | `5000.00` |

`SuperGetMV` resolves branch 02 first, falls back to blank-branch, then to the third-arg default.

## 5. New index with nickname on a TOTVS table

The customer needs a fast "search SA1 by CNPJ" path. Standard SIX has it as ORDEM `4` (which is fine), but a customer report is going to use `DbSetOrder`. Robust code:

```advpl
DBSelectArea("SA1")
DBOrderNickName("SA1CGC")   // resolved at runtime; survives TOTVS reordering
SA1->(DBSeek(xFilial("SA1") + cCNPJ))
```

If the nickname isn't yet present on the standard index, **add it via Configurador** (Edit → Índices → select the index → set Nickname). Standard indexes can get nicknames without breaking anything.

## 6. Custom virtual field — display the group description

Show the product's group description as a column in browses without storing it.

**SX3 row** (insert on SB1):

| Field | Value |
| --- | --- |
| X3_CAMPO | `B1_DESCGR` |
| X3_TIPO | `C` |
| X3_TAMANHO | 40 |
| X3_TITULO | `Desc.Grupo` |
| X3_CONTEXT | `V` (virtual) |
| X3_RELACAO | `Posicione("SBM",1,xFilial("SBM")+B1_GRUPO,"BM_DESC")` |
| X3_INIBRW | `Posicione("SBM",1,xFilial("SBM")+B1_GRUPO,"BM_DESC")` |
| X3_BROWSE | `S` |
| X3_PROPRI | `U` (auto) |

`B1_DESCGR` will appear in every SB1 browse with the group's description, computed live. Use `GetSx3Cache` in the validator/relacao if performance becomes an issue on large browses.

## 7. Trigger — auto-fill on field change

When `A1_EST` (state) changes, populate `A1_INSCR` (state-tax) with the correct mask.

**SX3**: `A1_EST.X3_TRIGGER = 'S'`.

**SX7 row**:

| Field | Value |
| --- | --- |
| X7_CAMPO | `A1_EST` |
| X7_SEQUENC | `01` (next free) |
| X7_TIPO | `P` (primário) |
| X7_REGRA | `IE(M->A1_INSCR, M->A1_EST)` |
| X7_CDOMIN | `A1_INSCR` |
| X7_PROPRI | `U` |

Created via Configurador → Gatilhos → Incluir. The trigger fires on `A1_EST` validation and writes the result of `X7_REGRA` to `A1_INSCR`.

## 8. SXG group for a custom concept

The customer has three custom tables that all carry the same "internal ID" code, 12 chars. Without SXG, resizing the field on one table means resizing on all three manually.

**SXG row**:

| Field | Value |
| --- | --- |
| XG_GRUPO | `Z01` |
| XG_DESCRI | `Identificador interno` |
| XG_SIZE | `12` |
| XG_SIZEMIN | `8` |
| XG_SIZEMAX | `20` |
| XG_PICTURE | `@!` |

Then link the fields:

- `ZA0_INTID.X3_GRPSXG = 'Z01'`
- `ZB0_INTID.X3_GRPSXG = 'Z01'`
- `ZC0_INTID.X3_GRPSXG = 'Z01'`

Changing `Z01.XG_SIZE` to `14` updates the size on all three tables atomically.

## 9. The pre-producao.md checklist

Every example above should land as a row in `.claude/plans/<slug>/pre-producao.md`.

**Everything in this file is copy-pasteable.** The operator applies it by copying values straight into Configurador screens, so every value is the literal content to be typed — complete, exactly as it goes into the screen. No placeholders (`<...>`, `a definir`), no ellipses (`…`), no prose mixed into value cells ("yes, financeiro module" is prose; the cell carries the literal choice). Short values go in table cells; multi-line/long values (help de campo, X3_RELACAO expressions, combo lists) each get their own fenced code block so one selection copies the whole value.

Template:

```markdown
# Pre-produção — <slug>

## SX2 — tabelas novas

| X2_CHAVE | X2_NOME | X2_MODO | X2_AUTREC | X2_STAMP | X2_INSDT |
| --- | --- | --- | --- | --- | --- |
| ZA0 | Histórico de Limite | E | 1 | 1 | 1 |

## SX3 — campos novos

| Tabela | Campo | Tipo | Tamanho | Decimal | Título | Descrição | Picture | Context | Obrigat | Used | X3_F3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SA1 | A1_CREDLIM | N | 14 | 2 | Limite crédito | Limite de crédito por cliente | @E 99,999,999.99 | R | N | financeiro | — |
| ZA0 | ZA0_FILIAL | C | 2 | 0 | Filial | Filial do sistema | @! | R | N | key | — |

## Helps de campo (F1)

Um bloco por campo — copiar o texto inteiro para o help do campo no Configurador.

### SA1 → A1_CREDLIM

```
Limite de crédito específico deste cliente, em reais. Quando preenchido com valor maior que zero, sobrepõe o limite de crédito padrão da empresa na análise de crédito dos pedidos de venda. Quando zero, o sistema usa o limite padrão configurado pelo administrador.
```

### ZA0 → ZA0_FILIAL

```
Filial do sistema à qual este registro pertence. Preenchida automaticamente.
```

## SIX — índices novos

| Tabela | Ordem | Chave | Descrição | Nickname | ShowPesq |
| --- | --- | --- | --- | --- | --- |
| ZA0 | 1 | ZA0_FILIAL+ZA0_CLIENT+ZA0_LOJA+DTOS(ZA0_DTALT) | Por cliente + data | ZA0CDT | S |

## SX6 — parâmetros novos

| X6_VAR | X6_TIPO | X6_CONTEUD | X6_DESCRIC |
| --- | --- | --- | --- |
| MV_ESCRDLM | N | 1000.00 | Limite de crédito default |

## Ordem de aplicação

1. SXG (grupos novos, se houver)
2. SX2 (tabelas novas)
3. SX3 (campos, incluindo o help de campo de cada um)
4. SIX (índices)
5. Atualizar base de dados (modo exclusivo)
6. SX6 (parâmetros)
7. SX7 (gatilhos)
8. SXB (consultas padrão, via skill protheus-consulta-padrao)
9. Validação física (apsdu / SQL)
```

The deploy is one Configurador session. Document it in advance so the operator can move through it confidently.
