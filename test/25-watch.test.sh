#!/usr/bin/env bash
# -w redraws on a timer, and must not spray escape codes when it is piped somewhere.
source "$(dirname "$0")/lib.sh"
tmp=$(mktemp)
timeout 4 env KUBECTL_ERR_GRACE=0 KUBECTL="kubectl --context $KCTX" \
  "$ROOT/kubectl-err" -w > "$tmp" 2>/dev/null || true
ticks=$(grep -c "ctrl-c to stop" "$tmp")
[ "$ticks" -ge 2 ] && ok "refreshed $ticks times in 4s" || bad "did not refresh (got $ticks ticks)"
escapes=$(cat -v "$tmp" | grep -c '\^\[' || true)
[ "$escapes" = 0 ] && ok "no escape codes when piped to a file" \
                   || bad "wrote $escapes escape sequences into a pipe"
rm -f "$tmp"
finish
