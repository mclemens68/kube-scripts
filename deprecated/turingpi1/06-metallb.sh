#!/bin/bash
set -euo pipefail

helm repo add metallb https://metallb.github.io/metallb || true
helm repo update

kubectl apply -f metallb-ns.yaml

helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --wait

kubectl apply -f metallb.yaml

echo
echo "Waiting for MetalLB pods..."
kubectl wait --namespace metallb-system \
  --for=condition=Ready pods \
  --all \
  --timeout=180s

echo
kubectl get pods -n metallb-system
echo
kubectl get ipaddresspools,l2advertisements -n metallb-system
