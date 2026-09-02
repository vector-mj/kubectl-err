#!/usr/bin/env bash
# A pod no node can fit reports the scheduler's own reason.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: unschedulable}
spec:
  containers:
  - {name: app, image: busybox:1.36, command: ["sleep","3600"],
     resources: {requests: {cpu: "500"}}}
YAML
out=$(err)
has "unschedulable +Pending"                    "$out" "unschedulable pod is reported"
has "unschedulable .*(Insufficient|nodes are available)" "$out" "detail carries the scheduler reason"
finish
