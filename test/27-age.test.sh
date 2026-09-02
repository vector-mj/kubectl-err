#!/usr/bin/env bash
# Every finding says how long it has been that way - the first question in any incident.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: aged}
spec:
  containers: [{name: app, image: invalid.example.com/nope:v1}]
YAML
eventually 120 "aged +(ImagePullBackOff|ErrImagePull)" "test pod is failing as expected"

out=$(err)
has "KIND +NAMESPACE +NAME +REASON +AGE +DETAIL" "$out" "the table has an AGE column"
has "aged +(ImagePullBackOff|ErrImagePull) +[0-9]+[smhd]" "$out" "the row carries a duration"

wide=$(err -o wide)
has "REASON +AGE +DETAIL +NODE +IMAGE" "$wide" "AGE sits before DETAIL in wide output too"

# JSON keeps it as seconds, so other tools can compare it.
# Capture first: kubectl-err exits 1 when it finds anything, and pipefail would
# propagate that through the pipe and sink the test regardless of what jq said.
js=$(err -o json)
printf '%s' "$js" | jq -e '[.[] | select(.name == "aged") | .age] | first | type == "number"' >/dev/null 2>&1 \
  && ok "JSON carries age as a number of seconds" || bad "JSON age is not numeric"
finish
