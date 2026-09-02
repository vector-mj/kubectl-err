#!/usr/bin/env bash
# An Ingress that never got a load balancer address routes nothing.
source "$(dirname "$0")/lib.sh"
ns_create
apply <<'YAML'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web}
spec:
  rules:
  - host: example.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend: {service: {name: whatever, port: {number: 80}}}
YAML
out=$(err)
has "Ingress +$NS +web +NoAddress" "$out" "address-less Ingress is reported"
finish
