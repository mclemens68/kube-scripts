#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi

CLUSTER_PREFIX="$1"

join_cmd="$(sudo kubeadm token create --print-join-command)"
join_cmd="${join_cmd} --cri-socket=unix:///run/containerd/containerd.sock"

for node in wk1 wk2; do
  host="ubuntu@${CLUSTER_PREFIX}-${node}-priv.clemenslabs.com"
  echo "Joining ${host}..."
  ssh -t "$host" "sudo ${join_cmd}"
done
