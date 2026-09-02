#!/usr/bin/env bash
# A suspended CronJob is silently not running; report it.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: batch/v1
kind: CronJob
metadata: {name: paused}
spec:
  schedule: "0 2 * * *"
  suspend: true
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers: [{name: c, image: busybox:1.36, command: ["true"]}]
YAML
out=$(err)
has "CronJob +$NS +paused +Suspended" "$out" "suspended CronJob is reported"
finish
