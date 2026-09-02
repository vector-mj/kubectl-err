#!/usr/bin/env bash
# A running pod failing its readiness probe is reported.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: notready}
spec:
  containers:
  - {name: app, image: busybox:1.36, command: ["sleep","3600"],
     readinessProbe: {exec: {command: ["false"]}, periodSeconds: 2}}
YAML
# Ready=false is also true while the pod is still pulling, so wait for the real state
eventually 180 "notready +NotReady" "running but unready pod is reported"
out=$(err)
has "notready +NotReady +[0-9]+[smhd] +containers not ready: app" "$out" "detail names the unready container"
finish
