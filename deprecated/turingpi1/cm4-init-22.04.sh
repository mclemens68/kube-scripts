#!/usr/bin/env bash
set -euo pipefail

# Basic OS prep
sudo apt update
sudo apt -y upgrade
sudo apt -y install vim git netcat-openbsd chrony jq curl gnupg ca-certificates apt-transport-https

# Set time zone
sudo timedatectl set-timezone America/Chicago

# Ensure hostname is correct before kubeadm join
# Edit this per node if needed
# sudo hostnamectl set-hostname turingpi4

# Enable required cgroups for Raspberry Pi / CM4
CMDLINE_FILE=""
if [ -f /boot/firmware/cmdline.txt ]; then
  CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/cmdline.txt ]; then
  CMDLINE_FILE="/boot/cmdline.txt"
else
  echo "Could not find cmdline.txt"
  exit 1
fi

sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%Y%m%d%H%M%S)"

if ! grep -q "cgroup_enable=memory" "$CMDLINE_FILE"; then
  sudo sed -i 's/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' "$CMDLINE_FILE"
fi

# Disable swap
sudo swapoff -a || true
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab || true
sudo apt purge -y dphys-swapfile || true
sudo apt -y autoremove
sudo rm -f /var/swap /swapfile
sudo sync

# Kernel modules for Kubernetes/containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Remove conflicting container runtimes if present
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" || true
done

# Install containerd from Docker's Ubuntu repo
sudo install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

sudo chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt-get -y install containerd.io

# Configure containerd for systemd cgroups
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes v1.28 components
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt update
sudo apt install -y kubelet kubeadm kubectl etcd-client
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet; it will fail until kubeadm join, which is normal
sudo systemctl enable kubelet

echo
echo "Node prep complete."
echo "Recommended: reboot now before kubeadm join."
echo
echo "After reboot, get join command from control plane:"
echo "  sudo kubeadm token create --print-join-command"
