#!/usr/bin/env bash
# -o wide answers "where is it and what is it running".
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: placed}
spec:
  containers:
  - {name: app, image: busybox:1.36, command: ["sleep","3600"],
     readinessProbe: {exec: {command: ["false"]}, periodSeconds: 2}}
YAML
# Ready=false is true while it is still pulling too, and the readiness probe needs a few
# periods to fail, so poll for the state instead of assuming it
eventually 180 "placed +NotReady" "test pod is unready as expected"
narrow=$(err)
wide=$(err -o wide)
hasnt "busybox:1.36"                     "$narrow" "narrow output omits the image"
has   "NODE +IMAGE"                      "$wide"   "wide output adds NODE and IMAGE"
has   "placed .*$CLUSTER.*busybox:1.36"  "$wide"   "wide row names the node and the image:tag"
finish
