#!/bin/bash
set -euo pipefail

helm repo add flannel https://flannel-io.github.io/flannel/ || true
helm repo update

kubectl create ns kube-flannel --dry-run=client -o yaml | kubectl apply -f -
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged

helm upgrade --install flannel flannel/flannel \
  --namespace kube-flannel \
  --set podCidr="10.244.0.0/16"
