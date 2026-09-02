#!/usr/bin/env bash
# Shared helpers. Every test sources this, gets its own namespace named after the file,
# and asserts against the real cluster that run.sh created.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLUSTER=${CLUSTER:-kuberr-test}
KCTX="kind-$CLUSTER"
NS=${NS:-$(basename "$0" .test.sh)}
FAILED=0

k()  { kubectl --context "$KCTX" "$@"; }
kn() { kubectl --context "$KCTX" -n "$NS" "$@"; }

# GRACE=0 by default so tests never wait out the startup window
err() {
  local out rc errf
  errf=$(mktemp)
  out=$(KUBECTL_ERR_GRACE=${GRACE:-0} KUBECTL="kubectl --context $KCTX" "$ROOT/kubectl-err" "$@" 2>"$errf")
  rc=$?
  # exit 2 means it never reached the cluster, which otherwise looks exactly like an
  # empty report and makes every assertion in the test fail for no visible reason
  [ "$rc" = 2 ] && echo "   !! kubectl-err exited 2: $(head -1 "$errf")"
  rm -f "$errf"
  printf '%s' "$out"
}

ns_create() {
  k create namespace "$NS" >/dev/null 2>&1
  # the default ServiceAccount is populated asynchronously; without this the first pod
  # of a fresh namespace is rejected with "serviceaccount default not found"
  timeout 60 bash -c "until kubectl --context $KCTX get sa default -n $NS >/dev/null 2>&1; do sleep 1; done"
}

apply()    { kn apply -f - >/dev/null; }
wait_for() { kn wait --timeout="${WAIT_TIMEOUT:-240s}" "$@" >/dev/null 2>&1 || echo "   !! wait failed: $*"; }

ok()  { echo "  ok   $1"; }
bad() { echo "  FAIL $1"; FAILED=1; }

has()   { grep -qE "$1" <<<"$2" && ok "$3" || bad "$3 (/$1/)"; }
hasnt() { grep -qE "$1" <<<"$2" && bad "$3 leaked (/$1/)" || ok "$3"; }

# for states that need the control plane to catch up
eventually() { # eventually <seconds> <pattern> <label>
  local deadline=$((SECONDS + $1)) pat=$2 label=$3 out
  while [ $SECONDS -lt $deadline ]; do
    out=$(err)
    if grep -qE "$pat" <<<"$out"; then ok "$label"; return 0; fi
    sleep 5
  done
  bad "$label (/$pat/ never appeared)"
  return 1
}

finish() { exit "$FAILED"; }
