#!/bin/bash
set -euo pipefail

helm repo add projectcalico https://docs.tigera.io/calico/charts || true
helm repo update

kubectl create namespace tigera-operator --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install calico projectcalico/tigera-operator \
  --version v3.28.2 \
  --namespace tigera-operator
