#!/usr/bin/env bash
# A namespace wedged in Terminating by a finalizer. Deliberately ignored for its first
# minute, since an ordinary namespace deletion finishes in seconds.
source "$(dirname "$0")/lib.sh"
DOOMED="$NS-doomed"
k create namespace "$DOOMED" >/dev/null 2>&1
timeout 60 bash -c "until kubectl --context $KCTX get sa default -n $DOOMED >/dev/null 2>&1; do sleep 1; done"
k apply -n "$DOOMED" -f - >/dev/null <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: holdout, finalizers: ["kuberr.test/hold"]}
spec:
  containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
YAML
k delete namespace "$DOOMED" --wait=false >/dev/null 2>&1
out=$(err)
hasnt "Namespace +- +$DOOMED " "$out" "a fresh deletion is not yet an incident"
eventually 150 "Namespace +- +$DOOMED +Terminating" "namespace stuck past the grace window is reported"
finish
