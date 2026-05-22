#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
K8S_MINOR="v1.36"

sudo mkdir -p /etc/needrestart/conf.d
echo '$nrconf{restart} = "a";' | sudo tee /etc/needrestart/conf.d/99-auto-restart.conf >/dev/null

read -rp "Enter hostname for this node (e.g. turingpi1): " NEW_HOSTNAME

if [[ -z "${NEW_HOSTNAME}" ]]; then
  echo "Hostname cannot be empty."
  exit 1
fi

CURRENT_HOSTNAME=$(hostname)

if [[ "${CURRENT_HOSTNAME}" != "${NEW_HOSTNAME}" ]]; then
  sudo hostnamectl set-hostname "${NEW_HOSTNAME}"

  if grep -q '^127.0.1.1' /etc/hosts; then
    sudo sed -i "s/^127.0.1.1.*/127.0.1.1 ${NEW_HOSTNAME}/" /etc/hosts
  else
    echo "127.0.1.1 ${NEW_HOSTNAME}" | sudo tee -a /etc/hosts >/dev/null
  fi
fi

hostnamectl

sudo apt-get update

sudo apt-get -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  upgrade

sudo apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  vim git netcat-openbsd chrony jq curl gnupg ca-certificates apt-transport-https nfs-common

sudo timedatectl set-timezone America/Chicago
sudo systemctl enable --now chrony
timedatectl status

if [ -f /boot/firmware/cmdline.txt ]; then
  CMDLINE_FILE="/boot/firmware/cmdline.txt"
elif [ -f /boot/cmdline.txt ]; then
  CMDLINE_FILE="/boot/cmdline.txt"
else
  echo "Could not find cmdline.txt"
  exit 1
fi

sudo cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak.$(date +%Y%m%d%H%M%S)"

for arg in cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1; do
  if ! grep -qw "$arg" "$CMDLINE_FILE"; then
    sudo sed -i "s/$/ $arg/" "$CMDLINE_FILE"
  fi
done

sudo swapoff -a || true
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab || true
sudo apt-get purge -y dphys-swapfile || true
sudo apt-get autoremove -y
sudo rm -f /var/swap /swapfile

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
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

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" || true
done

sudo install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

sudo chmod a+r /etc/apt/keyrings/docker.gpg

. /etc/os-release

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl enable --now containerd

curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable kubelet

read -rp "Configure this node as NFS server for Kubernetes storage? [y/N]: " CONFIGURE_NFS_SERVER

if [[ "${CONFIGURE_NFS_SERVER,,}" == "y" ]]; then
  sudo apt-get install -y nfs-kernel-server

  sudo mkdir -p /data
  sudo chown nobody:nogroup /data
  sudo chmod 0777 /data

  sudo mkdir -p /etc/exports.d

  echo '/data *(rw,sync,no_subtree_check,no_root_squash)' | \
    sudo tee /etc/exports.d/k8s-data.exports >/dev/null

  sudo exportfs -ra
  sudo systemctl enable --now nfs-server
  sudo systemctl restart nfs-server

  echo
  showmount -e localhost
  sudo exportfs -v
fi

echo
echo "Installed versions:"
kubeadm version
kubectl version --client=true
kubelet --version
containerd --version

K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)

curl -LO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_arm64.tar.gz"
tar -xzf k9s_Linux_arm64.tar.gz
sudo mv k9s /usr/local/bin/
rm -f LICENSE README.md k9s_Linux_arm64.tar.gz
k9s version

echo
echo "Node prep complete."
echo "Reboot before kubeadm init/join."
