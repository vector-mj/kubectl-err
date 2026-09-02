#!/usr/bin/env bash
# Node health, cluster-wide. Runs last: it stops the kubelet, which leaves the cluster
# unusable for anything after it. The API server keeps serving because its static pod
# container stays up, so the report can still be produced.
source "$(dirname "$0")/lib.sh"
NODE="$CLUSTER-control-plane"

k cordon "$NODE" >/dev/null
out=$(err)
has "Node +- +$NODE +SchedulingDisabled" "$out" "cordoned node is reported"

docker exec "$NODE" systemctl stop kubelet >/dev/null 2>&1
eventually 240 "Node +- +$NODE +NotReady" "node that stopped reporting is flagged NotReady"

out=$(err)
first=$(grep -vE "^KIND" <<<"$out" | grep -E "^[A-Za-z]" | head -1 | awk '{print $1}')
[ "$first" = "Node" ] && ok "node trouble sorts above everything else" \
                      || bad "expected a Node row first, got $first"
finish
