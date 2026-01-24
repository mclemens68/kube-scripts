#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi

CLUSTER_PREFIX="$1"
CONTROL_PLANE_ENDPOINT="${CLUSTER_PREFIX}-mstr-priv.clemenslabs.com"

echo "Initializing Kubernetes control plane (Cilium cluster)..."

sudo kubeadm init \
  --kubernetes-version=v1.34.3 \
  --control-plane-endpoint="${CONTROL_PLANE_ENDPOINT}" \
  --service-cidr=10.98.0.0/16 \
  --pod-network-cidr=10.246.0.0/16 \
  --service-dns-domain=cluster.local \
  --cri-socket=unix:///run/containerd/containerd.sock

echo "Setting up kubeconfig..."

mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Uncommennt to allow pods to be able to run on control plane node
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Cluster initialized successfully."
echo "Next step: install Cilium CNI."
