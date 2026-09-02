#!/usr/bin/env bash
# One typo in a selector takes a service down while every pod and workload looks healthy.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Service
metadata: {name: orphan}
spec:
  selector: {app: nothing-matches-this}
  ports: [{port: 80}]
---
apiVersion: v1
kind: Pod
metadata: {name: real, labels: {app: real}}
spec:
  containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
---
apiVersion: v1
kind: Service
metadata: {name: wired}
spec:
  selector: {app: real}
  ports: [{port: 80}]
YAML
wait_for --for=condition=Ready pod/real
out=$(err)
has   "Service +$NS +orphan +NoEndpoints" "$out" "service with no endpoints is reported"
hasnt "Service +$NS +wired "              "$out" "service with endpoints stays out"
finish
