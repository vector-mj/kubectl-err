#!/usr/bin/env bash
# Flag handling: kubectl's own conventions, truncation control, and rejecting bad input.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: chatty}
spec:
  containers: [{name: app, image: invalid.example.com/a-very-long-image-name-that-produces-a-long-error:v1}]
YAML
eventually 120 "chatty +(ImagePullBackOff|ErrImagePull)" "test pod is failing as expected"

out=$(KUBECTL_ERR_GRACE=0 KUBECTL="kubectl" "$ROOT/kubectl-err" --context "$KCTX" 2>/dev/null)
has "chatty" "$out" "--context selects the cluster"

short=$(err | grep chatty | wc -c)
full=$(err --full | grep chatty | wc -c)
[ "$full" -gt "$short" ] && ok "--full stops truncating ($short -> $full chars)" \
                         || bad "--full changed nothing ($short vs $full chars)"

# these exit non-zero on purpose, so capture the message instead of piping (pipefail)
msg=$("$ROOT/kubectl-err" -o yaml 2>&1 || true)
grep -q "takes wide or json" <<<"$msg" \
  && ok "an unsupported -o value is rejected" || bad "bad -o value was not rejected"
msg=$("$ROOT/kubectl-err" -g abc 2>&1 || true)
grep -q "whole seconds" <<<"$msg" \
  && ok "a non-numeric grace is rejected" || bad "bad -g value was not rejected"
finish
