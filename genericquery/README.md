# Skill: genericquery (Protheus)

Consulta tabelas do TOTVS Protheus pela API nativa `genericQuery` (REST + OAuth2),
sem acesso direto ao banco. Para uso com Claude Code.

## Instalar

Copie a pasta `genericquery/` para o diretorio de skills do Claude Code:

```
~/.claude/skills/genericquery/
```

(Windows: `C:\Users\<voce>\.claude\skills\genericquery\`)

## Requisitos

- Claude Code
- `bash`, `curl` e `python` no PATH (no Windows, o Git Bash ja tem)
- REST Server do Protheus com `SECURITY=1`

## Primeiro uso (uma vez por projeto)

1. Copie `.genericquery.example.json` para a raiz do seu projeto como `.genericquery.json`.
2. Preencha `baseUrl`, `username`, `password` e `tenantId` de `dev` e `prod`.
3. **Nao versione** esse arquivo (tem senha). Adicione `.genericquery.json` ao `.gitignore`.

`baseUrl` = prefixo tal que `<baseUrl>/oauth2/v1/token` e
`<baseUrl>/framework/v1/genericQuery` resolvam. Em muitos ambientes o caminho tem
`/api` duplicado (ex.: `http://host:8070/api/api`) — confirme por teste.
`tenantId` = `"empresa,filial"` (ex.: `"01,01"`).

## Usar

Pelo Claude, e so pedir: *"consulta a SE4 na base dev"*, *"qual o C5_PEDCLI do pedido X"*.

Ou direto pelo runner:

```bash
bash ~/.claude/skills/genericquery/scripts/gq.sh ./.genericquery.json dev \
  "SE4" "E4_CODIGO,E4_DESCRI,E4_TIPO" "E4_TIPO='1'"
```

`FilialFilter`/`DeletedFilter` da API ja sao `true` — nao precisa por `D_E_L_E_T_`
nem `[ALIAS]_FILIAL` no `where`.

Documentacao completa e parametros: veja `SKILL.md`.

## Seguranca

O `.genericquery.json` guarda usuario/senha em texto. Mantenha-o fora do git
(no `.gitignore` do projeto ou no gitignore global).
