#!/usr/bin/env bash
set -euo pipefail

API="${SKILLSCAKE_API_BASE:-https://api.skillscake.com}"
WEB="https://skillscake.com"
MAX=30000          # server cap: skill text + notes combined
POLL=4; TIMEOUT=1200

for bin in curl zip unzip; do
  command -v "$bin" >/dev/null || { echo "status=error reason=missing_dep dep=$bin"; exit 1; }
done

skill="" notes="" tier="" out="" label=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skill) skill="$2"; shift 2 ;;
    --notes) notes="$2"; shift 2 ;;
    --tier)  tier="$2";  shift 2 ;;
    --out)   out="$2";   shift 2 ;;
    --label) label="$2"; shift 2 ;;
    *) echo "status=error reason=bad_arg arg=$1"; exit 1 ;;
  esac
done
{ [ -n "$tier" ] && [ -n "$out" ]; } || { echo "status=error reason=usage need=--tier,--out"; exit 1; }
{ [ -n "$skill" ] || [ -n "$notes" ]; } || { echo "status=error reason=no_input need=--skill_or_--notes"; exit 1; }

key="${SKILLSCAKE_API_KEY:-}"
[ -n "$key" ] || { echo "status=error reason=no_key action=$WEB/account"; exit 10; }
auth=(-H "Authorization: Bearer $key")

# Map an API error to a reason + where to send the user.
route() {
  local code="$1" b="$2" detail
  # grep finds nothing when the body has no "code" field — don't let that abort under set -e.
  detail=$(printf '%s' "$b" | grep -o '"code":"[^"]*"' | sed 's/.*:"//;s/"//') || true
  case "$code" in
    402) echo "status=error reason=quota_exhausted action=$WEB/account" ;;
    403) [ "$detail" = no_card ] && echo "status=error reason=no_card action=$WEB/setup-card" \
                                 || echo "status=error reason=forbidden action=$WEB/account" ;;
    401) echo "status=error reason=invalid_key action=$WEB/account" ;;
    *)   echo "status=error reason=api_error http=$code" ;;
  esac
}

chars=0
[ -n "$notes" ] && chars=$(wc -m < "$notes" | tr -d ' ')
if [ -n "$skill" ]; then
  sc=$(find "$skill" -type f -not -path '*/.git/*' -not -name '*.pyc' -not -name '.DS_Store' \
       -exec cat {} + 2>/dev/null | wc -m | tr -d ' ')
  chars=$((chars + sc))
fi
if [ "$chars" -gt "$MAX" ]; then
  echo "status=error reason=too_long chars=$chars max=$MAX"; exit 1
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# Upgrade: zip the folder and stage it.
s3=""
if [ -n "$skill" ]; then
  ( cd "$skill" && zip -rqX "$tmp/skill.zip" . -x '.git/*' '*/__pycache__/*' '*.pyc' '.DS_Store' )
  up=$(curl -sS -m 60 -w $'\n%{http_code}' "${auth[@]}" -H "Content-Type: application/zip" \
       --data-binary @"$tmp/skill.zip" "$API/runs/upload-skill")
  [ "$(printf '%s' "$up" | tail -n1)" = 200 ] || { route "$(printf '%s' "$up" | tail -n1)" "$up"; exit 1; }
  s3=$(printf '%s' "$up" | sed '$d' | sed -n 's/.*"s3_key"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

# JSON-encode the notes: drop control chars (keep newline), escape \ and ", join lines with \n.
prompt=null
if [ -n "$notes" ]; then
  esc=$(tr -d '\000-\011\013-\037' < "$notes" \
        | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
        | awk 'BEGIN{ORS=""}{if(NR>1)printf"\\n"; printf"%s",$0}')
  prompt="\"$esc\""
fi
s3j=null;  [ -n "$s3" ]    && s3j="\"$s3\""
lblj=null; [ -n "$label" ] && lblj="\"$label\""
body="{\"tier\":\"$tier\",\"input_s3_key\":$s3j,\"input_prompt\":$prompt,\"skill_label\":$lblj}"

cr=$(curl -sS -m 60 -w $'\n%{http_code}' "${auth[@]}" -H "Content-Type: application/json" -d "$body" "$API/runs")
[ "$(printf '%s' "$cr" | tail -n1)" = 201 ] || { route "$(printf '%s' "$cr" | tail -n1)" "$cr"; exit 1; }
rid=$(printf '%s' "$cr" | sed '$d' | sed -n 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

# Poll until the run finishes.
status=""; rbody=""; elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
  sleep "$POLL"; elapsed=$((elapsed + POLL))
  pr=$(curl -sS -m 30 -w $'\n%{http_code}' "${auth[@]}" "$API/runs/$rid")
  [ "$(printf '%s' "$pr" | tail -n1)" = 200 ] || { route "$(printf '%s' "$pr" | tail -n1)" "$pr"; exit 1; }
  rbody=$(printf '%s' "$pr" | sed '$d')
  status=$(printf '%s' "$rbody" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  case "$status" in completed|failed|error) break ;; esac
done
[ "$status" = completed ] || { echo "status=error reason=run_${status:-timeout} run_id=$rid"; exit 1; }

# Download and unpack the finished skill — a single {skill-name}/ folder, no metadata.
url=$(printf '%s' "$rbody" | sed -n 's/.*"result_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
curl -sS -m 180 -o "$tmp/result.zip" "$url"
mkdir -p "$out"
unzip -qo "$tmp/result.zip" -d "$out"
skill_dir=$(dirname "$(find "$out" -maxdepth 2 -name SKILL.md | head -n1)")
echo "status=ok run_id=$rid result_dir=$out skill_dir=$skill_dir"
