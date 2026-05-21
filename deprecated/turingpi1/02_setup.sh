#!/bin/bash
set -euo pipefail

sudo kubeadm init --config kubeadm-config.yaml --upload-certs

mkdir -p "$HOME/.kube"
sudo cp -f /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Allow workloads on control-plane nodes in this small homelab cluster
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true
