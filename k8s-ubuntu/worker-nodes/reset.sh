#!/usr/bin/env bash
set -euo pipefail

echo "=== Resetting worker node: $(hostname -f) ==="

# Stop kubelet so it doesn't thrash during/after reset
sudo systemctl disable --now kubelet || true

# Reset kubernetes node state
sudo kubeadm reset -f || true

# Remove CNI config + state (kubeadm does NOT do this)
sudo rm -rf /etc/cni/net.d/*
sudo rm -rf /var/lib/cni/*

# Optional: remove kubeconfigs if they exist on workers (harmless if absent)
rm -rf "${HOME}/.kube/"* || true
sudo rm -rf /root/.kube/* || true

# Flush firewall rules (scorched-earth; keep if this is a dedicated lab node)
# Use -w to wait for the xtables lock instead of failing.
sudo iptables -w 5 -F || true
sudo iptables -w 5 -t nat -F || true
sudo iptables -w 5 -t mangle -F || true
sudo iptables -w 5 -X || true
sudo nft flush ruleset || true

# Remove any leftover CRI objects in containerd
if command -v crictl >/dev/null 2>&1; then
  sudo crictl rm -fa || true
  sudo crictl rmp -fa || true
fi

# Docker cleanup is optional; only run if docker exists
if command -v docker >/dev/null 2>&1; then
  sudo docker system prune -af || true
fi

echo "=== Worker node reset complete (reboot will be triggered by the master script) ==="
