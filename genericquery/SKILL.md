---
name: genericquery
description: "Use quando precisar ler/consultar dados de tabelas do TOTVS Protheus (SE4, SA1, SF2, SC5, SB1, etc.) sem acesso direto ao banco de dados, ou quando o usuario disser 'genericQuery', 'consulta a base via API', 'roda um select na base dev/prod', 'qual o valor do campo X na tabela Y', 'confere no ambiente'. Skill especifica de Protheus (API REST nativa + OAuth2)."
license: MIT
metadata:
  domain: Protheus
  author: Johnni Moraes - TSC
  version: '1.0.0'
  category: Integration
---

# Protheus genericQuery (API nativa)

## Overview

Consulta tabelas do Protheus pela API nativa `genericQuery` (framework, baseada na
`FWAdapterBaseV2`): filtra, seleciona campos, ordena e pagina, sem acesso direto ao
banco. Autentica por OAuth2 (grant_type=password) e chama o endpoint REST.

Referencia oficial: TDN GenericQuery (pageId 687146952).

## Config por projeto (dev + prod)

A config fica em `<raiz-do-projeto>/.genericquery.json` (uma vez por projeto).
Contem os ambientes `dev` e `prod`, cada um com `baseUrl`, `username`, `password`
e `tenantId`.

```json
{
  "default": "dev",
  "environments": {
    "dev":  { "baseUrl": "http://HOST:PORTA/api/api", "username": "USUARIO", "password": "SENHA", "tenantId": "EMPRESA,FILIAL" },
    "prod": { "baseUrl": "http://HOST:PORTA/api/api", "username": "USUARIO", "password": "SENHA", "tenantId": "EMPRESA,FILIAL" }
  }
}
```

- **`baseUrl`**: prefixo tal que `<baseUrl>/oauth2/v1/token` e
  `<baseUrl>/framework/v1/genericQuery` resolvam. Em muitos ambientes o caminho tem
  `/api` duplicado (ex.: `http://HOST:PORTA/api/api`) — confirmar por teste.
- **`tenantId`**: `"empresa,filial"` (ex.: `"01,01"`). Define a filial usada pelo
  `FilialFilter`.
- **Seguranca**: o arquivo tem credenciais em texto. **Nunca versionar.** Garantir o
  padrao `.genericquery.json` no `~/.gitignore_global`.

## Workflow

1. **Localizar a config**: procurar `.genericquery.json` na raiz do projeto (subir
   diretorios se preciso). Se **existir**, ir para o passo 3.

2. **Registrar (primeira vez)**: perguntar ao usuario (uma pergunta so, com os
   campos) e escrever `<raiz>/.genericquery.json`:
   - URL base **dev** e **prod** (avisar do `/api/api` se aplicavel)
   - usuario e senha (por ambiente; se forem os mesmos, repetir)
   - `tenantId` (empresa,filial)
   - ambiente `default` (dev|prod)
   Depois, garantir o ignore: se `.genericquery.json` nao estiver em
   `~/.gitignore_global`, adicionar a linha. Confirmar ao usuario o que foi gravado
   (sem exibir a senha).

3. **Consultar**: rodar o runner (nao reimplementar o curl na mao):

   ```bash
   bash ~/.claude/skills/genericquery/scripts/gq.sh <config.json> <env> "<tables>" "<fields>" "<where>" [page]
   ```

   Exemplos:
   ```bash
   # SE4 condicoes a vista (tipo 1)
   bash ~/.claude/skills/genericquery/scripts/gq.sh ./.genericquery.json dev \
     "SE4" "E4_CODIGO,E4_DESCRI,E4_TIPO" "E4_TIPO='1'"

   # SC5 pedidos com NF, pagina 2
   bash ~/.claude/skills/genericquery/scripts/gq.sh ./.genericquery.json prod \
     "SC5" "C5_NUM,C5_PEDCLI,C5_NOTA,C5_SERIE" "C5_NOTA<>''" 2
   ```

   Padroes do runner: `env` default = o `default` da config quando omitido. O
   `FilialFilter` e o `DeletedFilter` da API ja sao `true` por padrao, entao **nao**
   e preciso por `D_E_L_E_T_` nem `[ALIAS]_FILIAL` no `where`.

4. **Apresentar**: resumir os `items` retornados; citar `remainingRecords`/`hasNext`
   quando houver paginacao. Nunca imprimir a senha nem o token.

## Parametros da genericQuery

| Param | Obrig | Descricao |
|-------|-------|-----------|
| `tables` | sim | alias(es) da(s) tabela(s), separados por virgula |
| `fields` | nao | campos a retornar (sempre informar; evita SELECT *) |
| `where` | nao | filtro SQL (sem precisar de D_E_L_E_T_/_FILIAL) |
| `FromQry` | nao | FROM/JOIN manual para consultas com join |
| `FilialFilter` | nao | filtra `[ALIAS]_FILIAL` (default true) |
| `DeletedFilter` | nao | filtra `D_E_L_E_T_` (default true) |
| `page` | nao | pagina dos resultados |

Requer `SECURITY=1` no REST Server do ambiente. Se retornar 503 "API nao permitida",
a seguranca do REST esta desligada.

## Erros comuns

- **Connection reset no token**: enviar corpo vazio (`-d ""`) — o runner ja faz. Se
  persistir, revisar o `/api` duplicado no `baseUrl`.
- **`access_token` vazio**: usuario/senha invalidos ou grant errado.
- **401/403 na consulta**: token expirado (rodar de novo) ou usuario sem acesso a
  tabela/campo (campos sem acesso saem em `protectedDataFields`/`nivelFields`).
