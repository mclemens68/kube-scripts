#!/bin/bash
# Ensure cluster prefix is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
CLUSTER_PREFIX="$1"

kubeadm token create --print-join-command > join_cmd.txt
join_cmd=$(<join_cmd.txt)

ssh -t ubuntu@${CLUSTER_PREFIX}-wk1-priv.clemenslabs.com 'sudo '$join_cmd
ssh -t ubuntu@${CLUSTER_PREFIX}-wk2-priv.clemenslabs.com 'sudo '$join_cmd
