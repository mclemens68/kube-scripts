#!/usr/bin/env bash
set -euo pipefail

# add/update Helm repo
helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install cilium cilium/cilium \
  --namespace kube-system \
  --set cni.chainingMode=aws-cni \
  --set cni.exclusive=false \
  --set routingMode=native \
  --set enableIPv4Masquerade=false \
  --set envoy.enabled=false \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow}"
