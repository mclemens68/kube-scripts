#!/bin/bash
set -euo pipefail

# Allow workloads on control-plane nodes in this small homelab cluster
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Descriptive labels for your own selectors/organization
kubectl label node turingpi1 node-type=control-plane --overwrite
kubectl label node turingpi2 node-type=control-plane --overwrite
kubectl label node turingpi3 node-type=control-plane --overwrite
kubectl label node turingpi4 node-type=worker --overwrite

# Show worker role in kubectl get nodes ROLES column
kubectl label node turingpi4 node-role.kubernetes.io/worker=worker --overwrite

# Pin NFS provisioner to the node with the storage/export
kubectl label node turingpi3 storage=nfs --overwrite

kubectl get nodes -o wide
