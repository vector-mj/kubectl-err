#!/usr/bin/env bash
# Every shape a pod can take that kubectl renders as Error / Init:Error / OOMKilled.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: plain-error}
spec:
  restartPolicy: Never
  containers: [{name: app, image: busybox:1.36, command: ["sh","-c","exit 1"]}]
---
apiVersion: v1
kind: Pod
metadata: {name: init-error}
spec:
  restartPolicy: Never
  initContainers: [{name: init, image: busybox:1.36, command: ["sh","-c","exit 7"]}]
  containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
---
apiVersion: v1
kind: Pod
metadata: {name: oomkilled}
spec:
  restartPolicy: Never
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh","-c","dd if=/dev/zero of=/dev/shm/fill bs=1M count=200"]
    resources: {limits: {memory: "32Mi"}}
---
apiVersion: v1
kind: Pod
metadata: {name: config-error}
spec:
  restartPolicy: Never
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep","3600"]
    env: [{name: SECRET, valueFrom: {secretKeyRef: {name: nope-missing, key: k}}}]
YAML

echo "   what kubectl itself shows:"
kn get pods --no-headers 2>/dev/null | sed 's/^/     /'

eventually 180 "plain-error +Error"  "restartPolicy Never exiting non-zero"
out=$(err)
has "plain-error +Error +[0-9]+[smhd] +app: exit 1" "$out" "  ...with its exit code"

eventually 180 "init-error +(Error|Init:Error)" "a failed init container"
eventually 180 "oomkilled +(OOMKilled|Error)"   "an OOMKilled container"
eventually 180 "config-error +(CreateContainerConfigError|Error)" "a pod that cannot resolve its config"
finish
