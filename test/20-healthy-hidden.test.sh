#!/usr/bin/env bash
# The report must stay quiet about things that are fine.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: healthy}
spec:
  containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
---
apiVersion: v1
kind: Pod
metadata: {name: finished}
spec:
  restartPolicy: Never
  containers: [{name: app, image: busybox:1.36, command: ["true"]}]
YAML
wait_for --for=condition=Ready pod/healthy
wait_for --for=jsonpath='{.status.phase}'=Succeeded pod/finished
out=$(err)
hasnt "^Pod +$NS +healthy "  "$out" "a healthy pod stays out of the report"
hasnt "^Pod +$NS +finished " "$out" "a Succeeded pod stays out of the report"
finish
