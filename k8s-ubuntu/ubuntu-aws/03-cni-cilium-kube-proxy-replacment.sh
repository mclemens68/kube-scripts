#!/usr/bin/env bash
set -euo pipefail

# Ensure cluster prefix is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
export CLUSTER_PREFIX="$1"

# create namespace and allow privileged pods (for PodSecurity admission)
kubectl create ns cilium >/dev/null 2>&1 || true
kubectl label --overwrite ns cilium pod-security.kubernetes.io/enforce=privileged >/dev/null

# add/update Helm repo
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update >/dev/null

# install/upgrade Cilium + enable Hubble (observability): relay + UI + metrics
helm upgrade --install cilium cilium/cilium \
  --namespace cilium --create-namespace --wait \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost="${CLUSTER_PREFIX}-mstr-priv.clemenslabs.com" \
  --set k8sServicePort=6443 \
  --set ipam.mode=cluster-pool \
  --set ipam.operator.clusterPoolIPv4PodCIDRList[0]=10.247.0.0/16 \
  --set ipam.operator.clusterPoolIPv4MaskSize=24 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.relay.replicas=1 \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow}"

# Wait for Hubble components to become ready (best effort)
kubectl -n cilium rollout status deployment/hubble-relay --timeout=180s || true
kubectl -n cilium rollout status deployment/hubble-ui --timeout=180s || true

# Sanity check services exist before port-forwarding
if ! kubectl -n cilium get svc hubble-ui >/dev/null 2>&1; then
  echo "⚠️  Service cilium/hubble-ui not found. Skipping UI port-forward."
else
  echo "🚪 Port-forwarding Hubble UI to localhost:12000..."
  kubectl -n cilium port-forward svc/hubble-ui 12000:80 >/dev/null 2>&1 &
  echo "✅ You can now access the Hubble UI at http://localhost:12000"
fi

if ! kubectl -n cilium get svc hubble-relay >/dev/null 2>&1; then
  echo "⚠️  Service cilium/hubble-relay not found. Skipping relay port-forward."
else
  echo "🚪 Port-forwarding Hubble Relay to localhost:4245..."
  kubectl -n cilium port-forward svc/hubble-relay 4245:80 >/dev/null 2>&1 &
  echo "✅ You can now run: hubble observe --server localhost:4245"
fi
