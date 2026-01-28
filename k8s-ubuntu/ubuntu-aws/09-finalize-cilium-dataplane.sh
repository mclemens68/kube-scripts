#!/usr/bin/env bash
set -euo pipefail

# Verifies dataplane prerequisites and removes kube-proxy if present:
# - nodes Ready
# - cilium ds ready
# - kube-proxy replacement enabled in cilium-config
# - delete kube-proxy DS/CM if they exist
# - verify they are gone

NS="${CILIUM_NAMESPACE:-cilium}"

echo "Waiting for nodes to be Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=10m

echo "Waiting for Cilium DaemonSet to be ready (ns: $NS)..."
kubectl -n "$NS" rollout status ds/cilium --timeout=10m

echo "Verifying kube-proxy replacement is enabled in cilium-config..."
kpr="$(kubectl -n "$NS" get cm cilium-config -o jsonpath='{.data.kube-proxy-replacement}' 2>/dev/null || true)"
if [[ "$kpr" != "true" && "$kpr" != "strict" && "$kpr" != "probe" ]]; then
  echo "❌ kube-proxy replacement is NOT enabled (value='${kpr:-<missing>}'). Aborting."
  exit 1
fi
echo "✅ kube-proxy replacement appears enabled (value='$kpr')."

# Optional: show Cilium status if CLI exists
if command -v cilium >/dev/null 2>&1; then
  echo
  echo "Cilium status (namespace: $NS):"
  cilium status -n "$NS" | egrep -i 'Cilium:|Operator:|Envoy DaemonSet:|Hubble Relay:|kube-proxy|replacement' || true
fi

echo
echo "Deleting kube-proxy (DaemonSet + ConfigMap) in kube-system if present..."

if kubectl -n kube-system get ds kube-proxy >/dev/null 2>&1; then
  kubectl -n kube-system delete ds kube-proxy
  echo "✅ Deleted kube-system/DaemonSet kube-proxy."
else
  echo "ℹ️  kube-system/DaemonSet kube-proxy not found."
fi

if kubectl -n kube-system get cm kube-proxy >/dev/null 2>&1; then
  kubectl -n kube-system delete cm kube-proxy
  echo "✅ Deleted kube-system/ConfigMap kube-proxy."
else
  echo "ℹ️  kube-system/ConfigMap kube-proxy not found."
fi

echo
echo "Re-checking that kube-proxy objects are absent..."
if kubectl -n kube-system get ds kube-proxy >/dev/null 2>&1; then
  echo "❌ kube-system/DaemonSet kube-proxy still exists after delete."
  kubectl -n kube-system get ds kube-proxy -o wide || true
  exit 1
fi

if kubectl -n kube-system get cm kube-proxy >/dev/null 2>&1; then
  echo "❌ kube-system/ConfigMap kube-proxy still exists after delete."
  kubectl -n kube-system get cm kube-proxy -o yaml | sed -n '1,60p' || true
  exit 1
fi

echo "✅ kube-proxy DaemonSet + ConfigMap are absent."
echo "Done."
