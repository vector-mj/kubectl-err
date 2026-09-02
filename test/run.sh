#!/usr/bin/env bash
# Runs every test against one shared KinD cluster.
#   ./test/run.sh              create cluster, run all, tear down
#   KEEP=1 ./test/run.sh       leave the cluster up afterwards
#   ONLY=service ./test/run.sh run only tests whose name matches
set -uo pipefail
cd "$(dirname "$0")"

CLUSTER=${CLUSTER:-kuberr-test}
export CLUSTER

cleanup() {
  if [ -n "${KEEP:-}" ]; then
    echo ">> KEEP set, leaving cluster '$CLUSTER' up (kind delete cluster --name $CLUSTER)"
  else
    echo ">> tearing down"
    kind delete cluster --name "$CLUSTER" >/dev/null 2>&1
  fi
}
trap cleanup EXIT

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  echo ">> creating cluster $CLUSTER"
  kind create cluster --name "$CLUSTER" >/dev/null || { echo "FATAL: cluster would not start"; exit 1; }
fi

pass=0; fail=0
for t in [0-9]*.test.sh; do
  if [ -n "${ONLY:-}" ] && [[ "$t" != *"$ONLY"* ]]; then continue; fi
  echo "== $t"
  if bash "$t"; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" = 0 ] && echo "ALL TESTS PASS" || echo "TESTS FAILED"
exit "$fail"
