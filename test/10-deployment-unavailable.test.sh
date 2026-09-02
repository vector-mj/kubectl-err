#!/usr/bin/env bash
# A Deployment with fewer ready replicas than it wants is reported.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: shortfall}
spec:
  replicas: 2
  selector: {matchLabels: {app: shortfall}}
  template:
    metadata: {labels: {app: shortfall}}
    spec:
      containers: [{name: app, image: invalid.example.com/nope:v1}]
YAML
eventually 120 "Deployment +$NS +shortfall +Unavailable +[0-9]+[smhd] +0/2" "under-replicated Deployment is reported"
finish
