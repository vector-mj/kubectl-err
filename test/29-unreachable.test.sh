#!/usr/bin/env bash
# An unreachable cluster must fail loudly and fast. Reporting "All clear." because every
# list was skipped is the worst possible answer - it is indistinguishable from healthy.
source "$(dirname "$0")/lib.sh"

out=$("$ROOT/kubectl-err" --context no-such-context-exists 2>&1); rc=$?
[ "$rc" = 2 ] && ok "exits 2, distinct from 0 (clear) and 1 (findings)" \
              || bad "expected exit 2, got $rc"
has   "cannot reach the cluster" "$out" "says the cluster is unreachable"
hasnt "All clear"                "$out" "does not claim the cluster is healthy"
hasnt "cannot list"              "$out" "does not grind through every kind first"

# JSON consumers must not read an empty array as a clean bill of health
js=$("$ROOT/kubectl-err" --context no-such-context-exists -o json 2>/dev/null); rc=$?
[ "$rc" = 2 ] && ok "-o json also exits 2" || bad "-o json exited $rc"
[ "$js" != "[]" ] && ok "-o json does not emit an empty findings array" \
                  || bad "-o json emitted [] for an unreachable cluster"

# a blackholed address answers nothing at all: --request-timeout does not bound the TCP
# connect, so this is really testing the hard wall around the call
kc=$(mktemp)
cat > "$kc" <<'YAML'
apiVersion: v1
kind: Config
clusters: [{name: void, cluster: {server: "https://10.255.255.1:6443", insecure-skip-tls-verify: true}}]
contexts: [{name: void, context: {cluster: void, user: void}}]
current-context: void
users: [{name: void, user: {}}]
YAML
start=$SECONDS
"$ROOT/kubectl-err" --kubeconfig "$kc" -t 3 >/dev/null 2>&1; rc=$?
elapsed=$((SECONDS - start))
rm -f "$kc"
[ "$rc" = 2 ] && ok "a blackholed server still exits 2" || bad "blackholed server exited $rc"
[ "$elapsed" -le 20 ] && ok "gave up after ${elapsed}s, not the ~2min TCP default" \
                      || bad "took ${elapsed}s to give up"
finish
