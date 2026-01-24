#!/usr/bin/env bash
set -euo pipefail

# Ensure cluster prefix is provided
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
CLUSTER_PREFIX="$1"

WK1="ubuntu@${CLUSTER_PREFIX}-wk1-priv.clemenslabs.com"
WK2="ubuntu@${CLUSTER_PREFIX}-wk2-priv.clemenslabs.com"

echo "=== Resetting control-plane node: $(hostname -f) ==="

# Stop kubelet so it doesn't thrash during/after reset
sudo systemctl disable --now kubelet || true

# Reset kubernetes cluster
sudo kubeadm reset -f || true

# Remove CNI config + state (kubeadm does NOT do this)
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /var/lib/cni/*

# Remove local kubeconfigs for current user + root (common gotcha)
rm -rf "${HOME}/.kube/"* || true
sudo rm -rf /root/.kube/* || true

# Flush firewall rules (scorched-earth; keep if this is a dedicated lab node)
# Use -w to wait for the xtables lock instead of failing.
sudo iptables -w 5 -F || true
sudo iptables -w 5 -t nat -F || true
sudo iptables -w 5 -t mangle -F || true
sudo iptables -w 5 -X || true
sudo nft flush ruleset || true

# Remove any leftover CRI objects in containerd (e.g., exited CoreDNS pods)
if command -v crictl >/dev/null 2>&1; then
  sudo crictl rm -fa || true
  sudo crictl rmp -fa || true
fi

# Docker cleanup is optional; only run if docker exists
if command -v docker >/dev/null 2>&1; then
  sudo docker system prune -af || true
fi

echo "=== Resetting worker nodes: ${WK1}, ${WK2} ==="

# Run worker reset script (assumes it performs kubeadm reset + CNI cleanup there too)
ssh -t "${WK1}" '/home/ubuntu/reset.sh'
ssh -t "${WK2}" '/home/ubuntu/reset.sh'

# Reboot workers:
# A reboot usually drops the SSH session and returns a non-zero exit code (which would
# abort the script due to `set -e`). Run reboot detached and ignore SSH disconnect errors.
ssh "${WK1}" 'sudo nohup shutdown -r now >/dev/null 2>&1 &' || true
ssh "${WK2}" 'sudo nohup shutdown -r now >/dev/null 2>&1 &' || true

echo "=== Rebooting control-plane node ==="
sudo reboot
