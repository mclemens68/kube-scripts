#!/bin/bash
set -euo pipefail

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/ || true
helm repo update

kubectl label node turingpi3 storage=nfs --overwrite

helm upgrade --install nfs-subdir-external-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --create-namespace \
  --namespace nfs-system \
  --set nfs.server=turingpi3.clemenshome.com \
  --set nfs.path=/data \
  --set nodeSelector.storage=nfs
