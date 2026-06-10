# UPDDISTR & Migrador rules

UPDDISTR is the tool that applies a TOTVS release patch (or a Gestão de Ambientes project) to a customer's data dictionary. It walks every SX_ row in the incoming dictionary and decides, per column, whether to overwrite the customer's value or preserve it.

Knowing these rules is what lets you safely customise the standard dictionary. A column that "never overwrites" is fair game for customisation; a column that "always overwrites" will lose your change on the next release.

## General principle

> Characteristics the customer can configure are not overwritten by upgrades.
>
> Characteristics that are part of the product (descriptions in languages the customer didn't change, system-internal flags) are overwritten.

There are three regimes:

| Regime | Used by | Behaviour |
| --- | --- | --- |
| **Regra padrão** | Plain UPDDISTR releases | Conservative — preserves any column the customer can edit. |
| **Regra com dicionário de referência** | UPDDISTR when a reference dictionary was previously processed (LIB ≥ 2017-08-07) | Per-column diff: if the customer's value matches the previous TOTVS default, the upgrade applies the new TOTVS value. If the customer changed it, the customer's value is kept. Tracking via the reference dictionary. |
| **Regra do Gestão de Ambientes** | Pacotes built through Gestão de Ambientes (customer projects) | More aggressive — typically overwrites everything to ensure the project is fully applied. Used when the customer explicitly built a delta package. |

## SX2 (tables)

Existing tables only. New tables are always inserted intact.

| Column | Standard rule | Comment |
| --- | --- | --- |
| `X2_CHAVE`, `X2_ARQUIVO`, `X2_PATH` | Never overwrites | Identity / location. |
| `X2_MODO`, `X2_MODOUN`, `X2_MODOEMP` | Never overwrites | Share mode is customer-controlled. |
| `X2_USROBJ` | Never overwrites | Customer's maintenance-routine override. |
| `X2_ROTINA` | Overwrites only if empty | |
| `X2_UNICO` | Overwrites only if the new key is not contained in the current one | Adding columns to the primary key on the customer side is preserved. |
| `X2_STAMP`, `X2_INSDT` (with ref dict) | Preserves customer change | Once on, cannot revert (irreversible at the DB level). |
| All others (descriptions, display, module, …) | Always overwrites | TOTVS-owned. |

**Exceptions**: SR5, SYN, SYO have hard-coded `X2_PATH` rules.

## SX3 (fields)

This is the most granular dictionary. Existing fields only; new fields are inserted intact.

Highlights (full matrix in TDN):

| Column | Standard rule |
| --- | --- |
| `X3_NOME` | Never |
| `X3_TIPO` | Always |
| `X3_TAMANHO` | Overwrites if no SXG group AND configurador disallows resize, OR if the new size is forced-larger. If linked to SXG, the SXG size wins. |
| `X3_DECIMAL` | Same as tamanho. |
| `X3_PICTURE` | Overwrites if size/decimal changed in a numeric field, or if dictionary doesn't allow size change. |
| `X3_TITULO` | Never (preserved). With ref-dict: only if customer hadn't changed it. |
| `X3_DESCRIC` | Never (preserved). With ref-dict: only if customer hadn't changed it. |
| `X3_VISUAL` | Never (preserved). |
| `X3_BROWSE` | Never (preserved). With ref-dict: only if customer hadn't changed it. |
| `X3_OBRIGAT` | Never (preserved). |
| `X3_NIVEL` | Never (customer-exclusive). |
| `X3_RELACAO` (default initialiser) | Overwrites only if destination is empty, OR if migrator option "Sobrepõe inicializador" is checked. |
| `X3_VLDUSER` | Overwrites only if destination is empty. |
| `X3_VALID` | Always overwrites (system validation). |
| `X3_WHEN`, `X3_PICTVAR`, `X3_INIBRW`, `X3_F3` | Overwrites if the new value is not empty (i.e. doesn't blank existing customer config). |
| `X3_CBOX*` | Same — fills blanks, overwrites non-blanks if new value non-empty. |
| `X3_TRIGGER` | Overwrites only if new value is `S`. Doesn't disable an existing trigger. |
| `X3_USADO` | Overwrites if customer cannot change use, OR if all modules are in-use (adds the new modules). |
| `X3_RESERV` | Always (except `B1_DESC`). |
| `X3_ORDEM` | Default: not overwritten; reordered at the end of the process to close gaps. Forced overwrite only on dramatic changes (PROPRI flip, TIPO change, CONTEXT change). |
| `X3_FOLDER`, `X3_AGRUP`, `X3_PROPRI` | Always overwrites, with exceptions for the dramatic-change rule. |
| `X3_GRPSXG` | Always overwrites. |
| `X3_CONTEXT` | Always overwrites; a R→V or V→R flip cascades to override most other columns. |

**Implication for customisation**: customising `X3_TITULO`, `X3_DESCRIC`, `X3_VISUAL`, `X3_BROWSE`, `X3_OBRIGAT`, `X3_VLDUSER`, `X3_NIVEL` on a TOTVS-owned field is safe — the upgrade preserves your value. Customising `X3_TIPO`, `X3_TAMANHO` (without SXG), `X3_VALID`, `X3_RESERV` is not safe — the upgrade will overwrite.

## SIX (indexes)

- Existing customer indexes (`PROPRI = 'U'`): preserved.
- New TOTVS indexes: inserted; ORDEM may be rearranged to fit.
- TOTVS-shipped index update: applied.

Customer indexes whose `ORDEM` collides with a new TOTVS index get pushed to the next free position. **Always use `NICKNAME`** to insulate your code from these moves.

## SX6 (parameters)

Existing parameters only. New parameters are inserted intact.

| Column | Standard rule |
| --- | --- |
| `X6_FIL`, `X6_VAR`, `X6_TIPO` | Never (key / type) |
| `X6_CONTEUD`, `X6_CONTSPA`, `X6_CONTENG` | **Never overwrites** — customer's runtime value is sacred |
| `X6_DESCRIC`, `X6_DESC1`, `X6_DESC2` (and ES/EN siblings) | Always overwrites |
| `X6_PROPRI`, `X6_PYME` | Never |
| `X6_DEFPOR`, `X6_DEFSPA`, `X6_DEFENG` | Never (default reference) |
| `X6_VALID` | From 2020-11-23 LIB: always overwrites. Before: never. |
| `X6_EXPDEST` | Always |
| `X6_ACTIVE` | Always |

**Implication**: a parameter the customer changed keeps its value forever, until reset to `X6_DEFPOR` manually. A new TOTVS parameter ships with `X6_DEFPOR` as the active value.

## SX7 (triggers)

- Customer triggers (created via the Configurador, `X7_PROPRI = 'U'`): preserved, sequence shifted to come **after** TOTVS triggers so they fire last.
- TOTVS triggers: inserted/updated. On a version migration (e.g. 11→12), TOTVS triggers absent from the new version are deleted; customer triggers are kept.
- Key for matching: `X7_CAMPO + X7_SEQUENC`.

## SX5 (tabelas genéricas)

- Standard rule: never overwrites content (`X5_DESCRI`, `X5_DESCSPA`, `X5_DESCENG`).
- Gestão de Ambientes rule: always overwrites, even with blank values.

## SX1 (perguntas)

- `X1_PRESEL`, `X1_CNT01`, `X1_CNT02`: never overwrites.
- `X1_TAMANHO`: overwrites if no SXG; if SXG present, SXG wins.
- Others: always overwrites.

## SXB (consulta padrão)

UPDDISTR deletes every row of the consulta and reinserts the new TOTVS rows. **No partial update**. Customisations under standard `XB_ALIAS` codes vanish. See the `protheus-consulta-padrao` skill.

## SX9 (model entity-relationship)

Updates existing rows, inserts new ones. No deletes.

## SXG (field groups)

Inserted/updated, follows the same model as SX9.

## Practical guidance

**When customising a TOTVS-owned field**:

1. Check the column-by-column rule above.
2. If you need to change a column the rule overwrites, you have two options:
   - Use a different mechanism (`X3_VLDUSER` instead of `X3_VALID`, `X3_RELACAO` instead of trying to repurpose a TOTVS expression).
   - Document the override in `.claude/plans/<slug>/pre-producao.md` and re-apply manually after every UPDDISTR. Painful — try to avoid.

**When auditing post-upgrade damage**:

Compare `X6_CONTEUD` against `X6_DEFPOR` to see which parameters drifted from defaults — that is your "customer-intentional configuration" surface.

For SX3, compare `X3_PROPRI` to know what is customer-owned (`U`) vs TOTVS (`S`/blank). Customer-owned rows are insulated from UPDDISTR.

**Dictionary audit is non-disableable from recent LIBs.** Direct DB changes via APSDU / external scripts / SQL are logged and flagged. This is a feature, not a bug — embrace it.
