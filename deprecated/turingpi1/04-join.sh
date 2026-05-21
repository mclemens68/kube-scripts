#!/bin/bash
set -euo pipefail

# Worker join command
kubeadm token create --print-join-command > join-worker.sh
chmod +x join-worker.sh

# Control-plane join command with cert key
CERT_KEY=$(sudo kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)
kubeadm token create --print-join-command > join-base.txt
JOIN_BASE=$(cat join-base.txt)

echo "${JOIN_BASE} --control-plane --certificate-key ${CERT_KEY}" > join-control-plane.sh
chmod +x join-control-plane.sh

echo "Generated:"
echo "  ./join-control-plane.sh"
echo "  ./join-worker.sh

ssh -t matt@turingpi2 "sudo $(cat join-control-plane.sh)"
ssh -t matt@turingpi3 "sudo $(cat join-control-plane.sh)"
ssh -t matt@turingpi4 "sudo $(cat join-worker.sh)""
