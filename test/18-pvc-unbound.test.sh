#!/usr/bin/env bash
# A PVC that never bound leaves its pods stuck forever.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: data-0}
spec:
  storageClassName: no-such-class
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 1Gi}}
---
# no storageClassName: takes the cluster default, which on KinD (and EKS gp3, GKE
# standard-rwo) is WaitForFirstConsumer. Sitting Pending with no pod is its design,
# not a fault - reporting it would put noise on nearly every real cluster.
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: waiting-for-a-pod}
spec:
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 1Gi}}
YAML
out=$(err)
has   "PVC +$NS +data-0 +Pending"       "$out" "a claim no class can satisfy is reported"
hasnt "PVC +$NS +waiting-for-a-pod"     "$out" "a WaitForFirstConsumer claim is not a fault"
finish
