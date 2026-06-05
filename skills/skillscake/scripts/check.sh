#!/usr/bin/env bash
set -euo pipefail

API="${SKILLSCAKE_API_BASE:-https://api.skillscake.com}"
WEB="https://skillscake.com"

key="${SKILLSCAKE_API_KEY:-}"
if [ -z "$key" ]; then
  echo "status=error reason=no_key action=$WEB/account"
  echo "No key. Create one at $WEB/account, then export SKILLSCAKE_API_KEY." >&2
  exit 10
fi

resp=$(curl -sS -m 20 -w $'\n%{http_code}' -H "Authorization: Bearer $key" "$API/users/me") \
  || { echo "status=error reason=network"; exit 13; }
code=$(printf '%s' "$resp" | tail -n1)
body=$(printf '%s' "$resp" | sed '$d')

case "$code" in
  200) : ;;
  401|403) echo "status=error reason=invalid_key action=$WEB/account"; exit 11 ;;
  *)       echo "status=error reason=api_error http=$code"; exit 12 ;;
esac

num() { printf '%s' "$body" | grep -o "\"$1\":[0-9]*" | grep -o '[0-9]*$'; }
base=$(num base_remaining); pro=$(num pro_remaining)
if printf '%s' "$body" | grep -q '"card_last4":null'; then card=no; else card=yes; fi

echo "status=ok base_remaining=${base:-0} pro_remaining=${pro:-0} card_on_file=$card"
[ "$card" = no ] && echo "Note: no card on file — add one at $WEB/setup-card before a run." >&2
exit 0
