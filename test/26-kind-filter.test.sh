#!/usr/bin/env bash
# A positional kind list narrows the report; no argument means everything.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: badpod}
spec:
  containers: [{name: app, image: invalid.example.com/nope:v1}]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: badpvc}
spec:
  storageClassName: no-such-class
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 1Gi}}
YAML
eventually 120 "badpod +(ImagePullBackOff|ErrImagePull)" "test pod is failing as expected"

both=$(err)
has "^Pod +$NS +badpod"  "$both" "no argument checks pods"
has "^PVC +$NS +badpvc"  "$both" "no argument checks PVCs too"

only_pods=$(err po)
has   "^Pod +$NS +badpod" "$only_pods" "po keeps pod rows"
hasnt "^PVC "             "$only_pods" "po drops PVC rows"
hasnt "^Node "            "$only_pods" "po drops node rows"

two=$(err po,pvc)
has   "^Pod +$NS +badpod" "$two" "po,pvc keeps pods"
has   "^PVC +$NS +badpvc" "$two" "po,pvc keeps PVCs"
hasnt "^Node "            "$two" "po,pvc drops everything else"

msg=$("$ROOT/kubectl-err" po,widget 2>&1 || true)
grep -q "unknown kind: widget" <<<"$msg" \
  && ok "an unknown kind is rejected by name" || bad "unknown kind was not rejected"
grep -q "supported:" <<<"$msg" \
  && ok "the rejection lists the supported kinds" || bad "no list of supported kinds"
finish
