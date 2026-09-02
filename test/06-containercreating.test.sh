#!/usr/bin/env bash
# A pod wedged in ContainerCreating reports the state, how long, and WHY - the reason
# only exists in Events, so this also covers the event join.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: stuckmount}
spec:
  volumes: [{name: v, secret: {secretName: does-not-exist}}]
  containers:
  - {name: app, image: busybox:1.36, command: ["sleep","3600"],
     volumeMounts: [{name: v, mountPath: /v}]}
YAML
eventually 120 "stuckmount +ContainerCreating" "pod stuck creating is reported"
out=$(err)
has "stuckmount .*stuck for [0-9]+[smh]" "$out" "detail says how long it has been stuck"
has "stuckmount .*\|.*(FailedMount|not found)" "$out" "the Warning event explaining why is joined on"
finish
