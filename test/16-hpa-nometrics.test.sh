#!/usr/bin/env bash
# An HPA that cannot read metrics has silently stopped scaling.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: target}
spec:
  replicas: 1
  selector: {matchLabels: {app: target}}
  template:
    metadata: {labels: {app: target}}
    spec:
      containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: target-hpa}
spec:
  scaleTargetRef: {apiVersion: apps/v1, kind: Deployment, name: target}
  minReplicas: 1
  maxReplicas: 3
  metrics: [{type: Resource, resource: {name: cpu, target: {type: Utilization, averageUtilization: 80}}}]
YAML
eventually 180 "HPA +$NS +target-hpa +(ScalingActive|AbleToScale)" "HPA that cannot scale is reported"
finish
