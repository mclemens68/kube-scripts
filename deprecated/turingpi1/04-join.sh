#!/bin/bash
set -euo pipefail

CERT_KEY=$(sudo kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)

JOIN_BASE=$(kubeadm token create --print-join-command)

echo "${JOIN_BASE} --control-plane --certificate-key ${CERT_KEY}" > join-control-plane.sh
echo "${JOIN_BASE}" > join-worker.sh

chmod +x join-control-plane.sh join-worker.sh

echo "Generated:"
echo "  ./join-control-plane.sh"
echo "  ./join-worker.sh"
echo

echo "Joining control-plane nodes..."
ssh -t matt@turingpi2 "sudo $(cat join-control-plane.sh)"
ssh -t matt@turingpi3 "sudo $(cat join-control-plane.sh)"

echo "Joining worker node..."
ssh -t matt@turingpi4 "sudo $(cat join-worker.sh)"
