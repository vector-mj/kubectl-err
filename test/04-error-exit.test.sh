#!/usr/bin/env bash
# A run-once pod that exits non-zero is reported with its exit code.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: errexit}
spec:
  restartPolicy: Never
  containers: [{name: app, image: busybox:1.36, command: ["sh","-c","exit 3"]}]
YAML
wait_for --for=jsonpath='{.status.phase}'=Failed pod/errexit
out=$(err)
has "errexit +Error +[0-9]+[smhd] +app: exit 3" "$out" "non-zero exit is reported with its code"
finish
