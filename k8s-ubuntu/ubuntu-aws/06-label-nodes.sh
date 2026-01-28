#!/usr/bin/env bash
set -euo pipefail

# Ensure cluster prefix is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <cluster-prefix> [region]"
  exit 1
fi

CLUSTER_PREFIX="$1"
REGION="${2:-AWS}"

MASTER="${CLUSTER_PREFIX}-mstr.clemenslabs.com"
WK1="${CLUSTER_PREFIX}-wk1.clemenslabs.com"
WK2="${CLUSTER_PREFIX}-wk2.clemenslabs.com"

echo "Labeling nodes with topology region..."
echo "  topology.kubernetes.io/region=${REGION}"

# Topology region label
kubectl label node "$MASTER" topology.kubernetes.io/region="${REGION}" --overwrite
kubectl label node "$WK1"    topology.kubernetes.io/region="${REGION}" --overwrite
kubectl label node "$WK2"    topology.kubernetes.io/region="${REGION}" --overwrite

echo "Applying existing node-type / role labels..."

# Label master as control-plane
kubectl label node "$MASTER" node-type=control-plane --overwrite

# Label workers with custom node-type label
kubectl label node "$WK1" node-type=worker --overwrite
kubectl label node "$WK2" node-type=worker --overwrite

# Update ROLES label for worker nodes
kubectl label node "$WK1" node-role.kubernetes.io/worker= --overwrite
kubectl label node "$WK2" node-role.kubernetes.io/worker= --overwrite

echo "Node labeling complete."

echo "Verification:"
kubectl get nodes \
  -L topology.kubernetes.io/region \
  -L node-type
