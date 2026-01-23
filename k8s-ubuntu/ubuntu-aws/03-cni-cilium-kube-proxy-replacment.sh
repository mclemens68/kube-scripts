#!/usr/bin/env bash
set -euo pipefail

# create namespace and allow privileged pods (for PodSecurity admission)
kubectl create ns cilium || true
kubectl label --overwrite ns cilium pod-security.kubernetes.io/enforce=privileged

# add/update Helm repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# install Cilium (adjust --set values as needed for your cluster, e.g. IPAM mode or pod CIDR)
helm install cilium cilium/cilium --namespace cilium --wait \
  --set kubeProxyReplacement=strict \
  --set hostServices.enabled=true \
  --set nodeinit.enabled=true \
  # Enable Hubble (observability): relay + UI + metrics
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.relay.replicas=1 \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow}"

# Wait for Hubble components to become ready
kubectl -n cilium rollout status deployment/hubble-relay --timeout=120s || true
kubectl -n cilium rollout status deployment/hubble-ui --timeout=120s || true

# Port-forward Hubble UI to local machine
# Then open http://localhost:12000

echo "🚪 Port-forwarding Hubble Relay to localhost:12000..."
kubectl -n cilium port-forward svc/hubble-ui 12000:80 &
echo "✅ You can now run: hubble observe --server localhost:12000"
