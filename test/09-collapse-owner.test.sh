#!/usr/bin/env bash
# Replicas failing for the same reason collapse into one row naming their Deployment,
# so one bad rollout costs one line instead of one line per pod.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: api}
spec:
  replicas: 3
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers: [{name: api, image: invalid.example.com/api:v2.0.0}]
YAML
eventually 120 "Pod +$NS +Deployment/api" "pods collapse under their Deployment"
out=$(err)
rows=$(grep -cE "^Pod +$NS +(Deployment/api|api-)" <<<"$out")
[ "$rows" -le 2 ] && ok "3 replicas occupy $rows row(s), not 3" \
                  || bad "replicas not collapsed ($rows rows)"
finish
