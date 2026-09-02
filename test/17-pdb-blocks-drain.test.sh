#!/usr/bin/env bash
# A PDB allowing zero disruptions blocks every drain and node upgrade.
source "$(dirname "$0")/lib.sh"
ns_create
# a PDB matching no pods blocks nothing - there is nothing to evict - so the budget has
# to actually cover running pods for this to be a real finding
apply <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: guarded}
spec:
  replicas: 2
  selector: {matchLabels: {app: guarded}}
  template:
    metadata: {labels: {app: guarded}}
    spec:
      containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: strict}
spec:
  minAvailable: 2
  selector: {matchLabels: {app: guarded}}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: covers-nothing}
spec:
  minAvailable: 5
  selector: {matchLabels: {app: nothing-matches-this}}
YAML
wait_for --for=condition=Available deployment/guarded
eventually 120 "PDB +$NS +strict +NoDisruptionsAllowed" "a PDB that really blocks drains is reported"
out=$(err)
hasnt "PDB +$NS +covers-nothing" "$out" "a PDB covering no pods is not a finding"
finish
