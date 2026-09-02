#!/usr/bin/env bash
# A pod held by a finalizer past deletion is reported as stuck Terminating.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: terminating, finalizers: ["kuberr.test/hold"]}
spec:
  containers: [{name: app, image: busybox:1.36, command: ["sleep","3600"]}]
YAML
wait_for --for=condition=Ready pod/terminating
kn delete pod/terminating --wait=false >/dev/null 2>&1
# not "stuck" until it outlives its own graceful shutdown deadline (30s by default),
# otherwise every ordinary rollout and scale-down would be reported
out=$(err)
hasnt "terminating +Terminating" "$out" "a pod still inside its grace period is not stuck"
eventually 120 "terminating +Terminating +[0-9]+[smhd] +stuck since" "pod stuck terminating is reported"
out=$(err)
# a pod that is both deleting and failed must not produce two rows
[ "$(grep -cE "^Pod +$NS +terminating " <<<"$out")" -le 1 ] \
  && ok "reported exactly once" || bad "duplicate rows for one pod"
finish
