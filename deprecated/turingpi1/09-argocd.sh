#!/bin/bash
set -euo pipefail

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl -n argocd rollout status deploy/argocd-server --timeout=180s

kubectl -n argocd patch service argocd-server \
  --type='merge' \
  -p '{"spec":{"type":"LoadBalancer","loadBalancerIP":"192.168.1.3"}}'

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d > argocd-pw.txt

echo
echo "ArgoCD admin password saved to argocd-pw.txt"
