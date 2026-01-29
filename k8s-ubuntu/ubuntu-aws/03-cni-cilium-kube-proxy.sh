#!/usr/bin/env bash
set -euo pipefail

# create namespace and allow privileged pods (for PodSecurity admission)
kubectl create ns cilium || true
kubectl label --overwrite ns cilium pod-security.kubernetes.io/enforce=privileged

# add/update Helm repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# install Cilium with explicit pod CIDR
helm upgrade --install cilium cilium/cilium \
  --namespace cilium \
  --wait \
  --set ipam.mode=cluster-pool \
  --set ipam.operator.clusterPoolIPv4PodCIDRList[0]=10.246.0.0/16 \
  --set ipam.operator.clusterPoolIPv4MaskSize=24 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.relay.replicas=1 \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow}"