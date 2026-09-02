#!/usr/bin/env bash
# The false negative that mattered most: a rollout whose new revision times out while the
# OLD pods stay Ready. Replica counts look perfect, so a readyReplicas check says "all clear".
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: wedged}
spec:
  replicas: 1
  progressDeadlineSeconds: 30
  selector: {matchLabels: {app: wedged}}
  template:
    metadata: {labels: {app: wedged}}
    spec:
      containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
YAML
wait_for --for=condition=Available deployment/wedged
kn set image deployment/wedged app=invalid.example.com/nope:v9 >/dev/null 2>&1
eventually 180 "Deployment +$NS +wedged +RolloutStalled" "wedged rollout is reported"
out=$(err)
has "wedged +RolloutStalled +[0-9]+[smhd] +ProgressDeadlineExceeded" "$out" "detail names the deadline breach"
finish
