#!/usr/bin/env bash
set -euo pipefail

# create namespace and allow privileged pods (for PodSecurity admission)
kubectl create ns cilium || true
kubectl label --overwrite ns cilium pod-security.kubernetes.io/enforce=privileged

# add/update Helm repo
helm repo add cilium https://helm.cilium.io/
helm repo update

# install Cilium (adjust --set values as needed for your cluster, e.g. IPAM mode or pod CIDR)
helm install cilium cilium/cilium --namespace cilium --wait