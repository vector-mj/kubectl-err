#!/usr/bin/env bash
# A Job past its backoff limit is reported.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: batch/v1
kind: Job
metadata: {name: nightly}
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers: [{name: job, image: busybox:1.36, command: ["sh","-c","exit 1"]}]
YAML
eventually 120 "Job +$NS +nightly +Failed" "failed Job is reported"
finish
