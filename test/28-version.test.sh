#!/usr/bin/env bash
# --version, and the thing that actually goes wrong with versions: the binary and the
# krew manifest drifting apart.
source "$(dirname "$0")/lib.sh"

out=$("$ROOT/kubectl-err" --version 2>&1); rc=$?
[ "$rc" = 0 ] && ok "--version exits 0" || bad "--version exited $rc"
has "^kubectl-err v[0-9]+\.[0-9]+\.[0-9]+" "$out" "prints the name and a semver tag"

# it must not need a cluster, a kubeconfig, or even jq to answer
if PATH=/usr/bin:/bin KUBECTL=/nonexistent "$ROOT/kubectl-err" --version >/dev/null 2>&1; then
  ok "answers without touching the cluster"
else
  bad "--version needs a working cluster"
fi

# the version in the script and the one krew publishes have to agree, or users install
# something that reports a different version than the manifest promised
manifest=$(grep -E '^  version:' "$ROOT/.krew.yaml" | awk '{print $2}')
binary=$(printf '%s' "$out" | awk '{print $2}')
[ "$binary" = "$manifest" ] \
  && ok "script version matches .krew.yaml ($binary)" \
  || bad "version drift: script says $binary, .krew.yaml says $manifest"
finish
