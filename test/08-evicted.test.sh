#!/usr/bin/env bash
# An evicted pod is reported with the kubelet's reason.
# Real eviction needs node-pressure, so the status is set through the status subresource -
# the resulting object is exactly what a kubelet eviction leaves behind.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: evicted}
spec:
  restartPolicy: Never
  containers: [{name: app, image: busybox:1.36, command: ["sh","-c","exit 0"]}]
YAML
wait_for --for=jsonpath='{.status.phase}'=Succeeded pod/evicted
if ! kn patch pod/evicted --subresource=status --type=merge \
     -p '{"status":{"phase":"Failed","reason":"Evicted","message":"The node was low on resource: memory."}}' >/dev/null 2>&1; then
  echo "  SKIP the API server refused the status patch; eviction not reproducible here"
  finish
fi
out=$(err)
has "evicted +Evicted +[0-9]+[smhd] +The node was low on resource" "$out" "evicted pod is reported"
finish
