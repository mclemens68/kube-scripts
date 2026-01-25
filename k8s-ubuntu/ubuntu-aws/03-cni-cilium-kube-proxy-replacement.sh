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
  --set kubeProxyReplacement=true \
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

