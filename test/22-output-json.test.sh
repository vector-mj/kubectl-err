#!/usr/bin/env bash
# -o json has to be consumable by other tools, and ordered most-severe first.
source "$(dirname "$0")/lib.sh"
out=$(err -o json)
if printf '%s' "$out" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
  ok "emits a valid JSON array of $(printf '%s' "$out" | jq length) findings"
else
  bad "did not emit a valid JSON array"
fi
printf '%s' "$out" | jq -e '[.[].sev] | . == sort' >/dev/null 2>&1 \
  && ok "findings are ordered most-severe first" || bad "findings are not severity-ordered"
printf '%s' "$out" | jq -e 'all(has("kind") and has("namespace") and has("name") and has("reason") and has("detail"))' >/dev/null 2>&1 \
  && ok "every finding carries the full field set" || bad "findings are missing fields"
finish
