#!/bin/bash
set -euo pipefail

helm repo add metallb https://metallb.github.io/metallb || true
helm repo update

kubectl apply -f metallb-ns.yaml

helm upgrade --install metallb metallb/metallb \
  --namespace metallb-system \
  --wait \
  --set frrk8s.enabled=false \
  --set prometheus.serviceMonitor.enabled=false \
  --set prometheus.prometheusRule.enabled=false

kubectl apply -f metallb.yaml

echo
kubectl get pods -n metallb-system
echo
kubectl get ipaddresspools,l2advertisements -n metallb-system
