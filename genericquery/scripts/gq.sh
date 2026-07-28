#!/usr/bin/env bash
# genericQuery runner - consulta tabelas Protheus via API nativa (OAuth2 + genericQuery).
#
# Uso:
#   gq.sh <config.json> <env> "<tables>" ["<fields>"] ["<where>"] [page]
#
# Ex.:
#   gq.sh ./.genericquery.json dev "SE4" "E4_CODIGO,E4_DESCRI,E4_TIPO" "E4_TIPO='1'"
#   gq.sh ./.genericquery.json prod "SC5" "C5_NUM,C5_PEDCLI,C5_NOTA" "C5_NOTA<>''" 2
#
# A config tem environments.<env>.{baseUrl,username,password,tenantId}.
# baseUrl = prefixo tal que <baseUrl>/oauth2/v1/token e <baseUrl>/framework/v1/genericQuery resolvam.
set -uo pipefail

CONFIG="${1:?informe o caminho do config.json}"
ENVN="${2:?informe o ambiente (dev|prod)}"
TABLES="${3:?informe as tabelas}"
FIELDS="${4:-}"
WHERE="${5:-}"
PAGE="${6:-}"

if [ ! -f "$CONFIG" ]; then
  echo "ERRO: config nao encontrado: $CONFIG" >&2
  exit 2
fi

cfg() { python -c "import json,sys
c=json.load(open(sys.argv[1]))
e=c.get('environments',{}).get(sys.argv[2])
if e is None:
    sys.stderr.write('ambiente inexistente: '+sys.argv[2]+'\n'); sys.exit(9)
print(e.get(sys.argv[3],''))" "$CONFIG" "$ENVN" "$1"; }

BASE=$(cfg baseUrl) || exit 9
USR=$(cfg username)
PWD_=$(cfg password)
TEN=$(cfg tenantId)

if [ -z "$BASE" ]; then echo "ERRO: baseUrl vazio para env '$ENVN'" >&2; exit 2; fi

# 1) Token OAuth2 (grant_type=password, credenciais em header, corpo vazio obrigatorio)
TOK=$(curl -s --max-time 30 -X POST "$BASE/oauth2/v1/token?grant_type=password" \
  -H "username: $USR" -H "password: $PWD_" -d "")
AT=$(printf '%s' "$TOK" | python -c "import sys,json
try: print(json.load(sys.stdin).get('access_token',''))
except Exception: print('')")

if [ -z "$AT" ]; then
  echo "ERRO de autenticacao. Resposta do token:" >&2
  printf '%s\n' "$TOK" | head -c 500 >&2
  exit 3
fi

# 2) genericQuery (FilialFilter/DeletedFilter ja sao true por padrao na API)
ARGS=(-G "$BASE/framework/v1/genericQuery"
      --data-urlencode "tables=$TABLES"
      -H "Authorization: Bearer $AT" -H "tenantId: $TEN")
[ -n "$FIELDS" ] && ARGS+=(--data-urlencode "fields=$FIELDS")
[ -n "$WHERE" ]  && ARGS+=(--data-urlencode "where=$WHERE")
[ -n "$PAGE" ]   && ARGS+=(--data-urlencode "page=$PAGE")

RESP=$(curl -s --max-time 60 "${ARGS[@]}")
printf '%s' "$RESP" | python -m json.tool 2>/dev/null || printf '%s\n' "$RESP"
