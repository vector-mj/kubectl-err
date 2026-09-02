#!/usr/bin/env bash
# A container that keeps exiting non-zero is reported while it loops.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: crashloop}
spec:
  restartPolicy: Always
  containers: [{name: app, image: busybox:1.36, command: ["sh","-c","exit 1"]}]
YAML
wait_for --for=jsonpath='{.status.containerStatuses[0].state.waiting.reason}'=CrashLoopBackOff pod/crashloop
out=$(err)
# it alternates: waiting in backoff, terminated just after an exit, or briefly Running
# between restarts - all three are correct reports, and the third only exists because
# the Restarting rule was added for it.
has "crashloop +(CrashLoopBackOff|Error|Restarting)" "$out" "crash-looping pod is reported"
finish
