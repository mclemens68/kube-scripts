#!/usr/bin/env bash
set -euo pipefail

# Finalizes the Kubernetes dataplane by:
# - verifying Cilium health
# - enforcing kube-proxy replacement
# - removing kube-proxy (if present)
# - ensuring Hubble components are ready
# - optionally exposing Hubble locally

# Namespace where Cilium is installed
NS="${CILIUM_NAMESPACE:-cilium}"

echo "Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=10m

echo "Waiting for Cilium DaemonSet to be ready..."
kubectl -n "$NS" rollout status ds/cilium --timeout=10m

echo "Verifying kube-proxy replacement is enabled in cilium-config..."
kpr="$(kubectl -n "$NS" get cm cilium-config -o jsonpath='{.data.kube-proxy-replacement}' 2>/dev/null || true)"
if [[ "$kpr" != "true" ]]; then
  echo "❌ kube-proxy replacement is NOT enabled (cilium-config kube-proxy-replacement='$kpr'). Aborting."
  exit 1
fi
echo "✅ kube-proxy replacement is enabled."

# Optional: show Cilium status if CLI is installed
if command -v cilium >/dev/null 2>&1; then
  echo "Cilium status (namespace: $NS):"
  cilium status -n "$NS" | egrep -i 'Cilium:|Operator:|Envoy DaemonSet:|Hubble Relay:|ClusterMesh:|kube-proxy|replacement' || true
else
  echo "ℹ️  cilium CLI not found; skipping 'cilium status'."
fi

echo "Deleting kube-proxy (DaemonSet + ConfigMap) if present..."
kubectl -n kube-system delete ds kube-proxy --ignore-not-found
kubectl -n kube-system delete cm kube-proxy --ignore-not-found
echo "✅ kube-proxy removed (or was already absent)."

echo "Waiting for Hubble components..."
kubectl -n "$NS" rollout status deploy/hubble-relay --timeout=10m
kubectl -n "$NS" rollout status deploy/hubble-ui --timeout=10m
echo "✅ Hubble Relay/UI are ready."

# Optional: enable port-forwards by setting ENABLE_HUBBLE_PORTFW=1
if [[ "${ENABLE_HUBBLE_PORTFW:-0}" == "1" ]]; then
  # Best-effort cleanup of prior forwards on reruns
  pkill -f "kubectl -n ${NS} port-forward svc/hubble-ui 12000:80" 2>/dev/null || true
  pkill -f "kubectl -n ${NS} port-forward svc/hubble-relay 4245:80" 2>/dev/null || true

  echo "🚪 Port-forwarding Hubble UI to localhost:12000..."
  kubectl -n "$NS" port-forward svc/hubble-ui 12000:80 >/dev/null 2>&1 &
  echo "✅ You can now access the Hubble UI at http://localhost:12000"

  echo "🚪 Port-forwarding Hubble Relay to localhost:4245..."
  kubectl -n "$NS" port-forward svc/hubble-relay 4245:80 >/dev/null 2>&1 &
  echo "✅ You can now run: hubble observe --server localhost:4245"
else
  echo "ℹ️  Port-forwards disabled. Set ENABLE_HUBBLE_PORTFW=1 to enable."
fi
