#!/usr/bin/env bash
# Startup states are noise for a pod's first seconds and an incident after that.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: booting}
spec:
  volumes: [{name: v, secret: {secretName: does-not-exist}}]
  containers:
  - {name: app, image: busybox:1.36, command: ["sleep","3600"],
     volumeMounts: [{name: v, mountPath: /v}]}
YAML
eventually 120 "booting +ContainerCreating" "visible with no grace window"
out=$(GRACE=3600 err)
hasnt "booting " "$out" "hidden while inside the grace window"
out=$(GRACE=0 err)
has "booting +ContainerCreating" "$out" "visible again once the window is passed"
finish
