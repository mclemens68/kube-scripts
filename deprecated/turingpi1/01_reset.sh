#!/bin/bash
set -euo pipefail

WORKERS_AND_SECONDARY_CP=("turingpi2" "turingpi3" "turingpi4")

echo "Resetting remote nodes..."
for n in "${WORKERS_AND_SECONDARY_CP[@]}"; do
  echo "===== $n ====="
  ssh -t "matt@$n" 'sudo kubeadm reset -f || true
sudo systemctl stop kubelet containerd || true
sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes
sudo iptables -F || true
sudo iptables -t nat -F || true
sudo iptables -t mangle -F || true
sudo iptables -X || true
sudo nft flush ruleset || true
sudo systemctl start containerd || true'
done

echo "Resetting local control-plane node..."
sudo kubeadm reset -f || true
sudo systemctl stop kubelet containerd || true
sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes
rm -rf "$HOME/.kube"

sudo iptables -F || true
sudo iptables -t nat -F || true
sudo iptables -t mangle -F || true
sudo iptables -X || true
sudo nft flush ruleset || true

sudo systemctl start containerd || true

echo "Rebooting remote nodes..."
for n in "${WORKERS_AND_SECONDARY_CP[@]}"; do
  ssh -t "matt@$n" 'sudo reboot' || true
done

echo "Rebooting local node..."
sudo reboot
