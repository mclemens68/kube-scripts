#!/usr/bin/env bash
set -euo pipefail

export CILIUM_NAMESPACE=cilium

# Interactive safety check
echo "⚠️  WARNING: This script should only be run against clusters running Cilium with kube-proxy replacement enabled."
read -p "Type 'yes' to verify and continue: " confirmation
if [ "$confirmation" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

echo "Waiting for Cilium to be ready on all nodes..."
kubectl -n cilium rollout status ds/cilium --timeout=10m

echo "Verifying kube-proxy replacement mode..."
cilium status | egrep -i 'kube-proxy|replacement' || true

echo "Deleting kube-proxy (DaemonSet + ConfigMap)..."
kubectl -n kube-system delete ds kube-proxy --ignore-not-found
kubectl -n kube-system delete cm kube-proxy --ignore-not-found

echo "Done. kube-proxy removed."
