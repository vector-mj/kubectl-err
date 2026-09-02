#!/usr/bin/env bash
# An image that cannot be pulled is reported with the registry error.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: v1
kind: Pod
metadata: {name: badimage}
spec:
  containers: [{name: app, image: invalid.example.com/nope:v1}]
YAML
wait_for --for=jsonpath='{.status.containerStatuses[0].state.waiting.reason}'=ImagePullBackOff pod/badimage
out=$(err)
has "badimage +(ImagePullBackOff|ErrImagePull)" "$out" "unpullable image is reported"
has "badimage .*invalid.example.com"             "$out" "detail names the image that failed"
finish
