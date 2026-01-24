#!/usr/bin/env bash
set -euo pipefail

# This script has been tested on Ubuntu 22.04 and 24.04
#
# Optional flags:
#   --cilium-kpr            Enable sysctls required for Cilium kube-proxy replacement (rp_filter = 0)
#                           NOTE: Not compatible with Illumio C-VEN per your warning.
#   --non-interactive       Do not prompt; defaults to NO unless --cilium-kpr is provided.
#   -h|--help               Show usage.

usage() {
  cat <<'EOF'
Usage: ./init-node.sh [--cilium-kpr] [--non-interactive]

Options:
  --cilium-kpr            Enable sysctls for Cilium kube-proxy replacement (rp_filter=0).
                          WARNING: Not compatible with Illumio C-VEN.
  --non-interactive       Do not prompt; default is NO unless --cilium-kpr is set.
  -h, --help              Show this help.
EOF
}

ENABLE_CILIUM_KPR=false
NON_INTERACTIVE=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cilium-kpr)
      ENABLE_CILIUM_KPR=true
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

# Prompt only if not non-interactive AND flag not already set
if [[ "${NON_INTERACTIVE}" == "false" && "${ENABLE_CILIUM_KPR}" == "false" ]]; then
  echo
  read -r -p "Will this node run Cilium with kube-proxy replacement enabled? Type 'yes' to confirm: " CILIUM_KPR_REPLY
  if [[ "${CILIUM_KPR_REPLY,,}" == "yes" ]]; then
    ENABLE_CILIUM_KPR=true
  fi
fi

echo "=== Node bootstrap starting on: $(hostname -f) ==="
echo "Cilium kube-proxy replacement enabled: ${ENABLE_CILIUM_KPR}"
echo "Non-interactive mode: ${NON_INTERACTIVE}"

sudo apt update
sudo apt -y upgrade

# Base utilities
sudo apt -y install \
  vim git netcat-openbsd chrony \
  curl ca-certificates gnupg apt-transport-https

# Install Illumio VEN required packages
sudo apt -y install \
  dnsutils sed ipset \
  libcap2 libgmp10 libmnl0 libnfnetlink0 \
  net-tools uuid-runtime

# Set time zone
sudo timedatectl set-timezone America/Chicago

# Disable swap permanently
sudo sync
sudo swapoff -a
sudo apt -o Dpkg::Lock::Timeout=120 purge -y dphys-swapfile || true
sudo apt -y autoremove
sudo rm -f /var/swap
sudo sync

# Disable IPv6 for Illumio C-VEN (prevents IPv6 bypass paths)
cat <<'EOF' | sudo tee /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

# Kernel modules for containerd / Kubernetes networking
cat <<'EOF' | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctls for Kubernetes networking
cat <<'EOF' | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
# IPv6 is disabled earlier in the script; ensure bridge-nf-call-ip6tables is disabled to avoid no-op/warnings
net.bridge.bridge-nf-call-ip6tables = 0
EOF

# Conditionally add Cilium kube-proxy replacement settings
if [[ "${ENABLE_CILIUM_KPR}" == "true" ]]; then
  cat <<'EOF' | sudo tee -a /etc/sysctl.d/99-kubernetes-k8s.conf

# Cilium kube-proxy replacement enabled
# NOTE: This is NOT compatible with Illumio C-VEN
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
EOF
fi

# Apply all sysctl settings
sudo sysctl --system

# Log the decision for later debugging/auditing
cat <<EOF | sudo tee /etc/default/k8s-node-profile
# Written by init-node.sh on $(date -Is)
CILIUM_KUBE_PROXY_REPLACEMENT=${ENABLE_CILIUM_KPR}
NON_INTERACTIVE=${NON_INTERACTIVE}
EOF

# Remove Docker-related packages if present (Docker is NOT required)
for pkg in docker.io docker-doc docker-compose podman-docker docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin; do
  sudo apt-get remove -y "$pkg" || true
done
sudo rm -f /etc/apt/sources.list.d/docker.list || true
sudo rm -f /etc/apt/keyrings/docker.gpg || true

# Install containerd (CRI runtime for kubeadm)
sudo apt update
sudo apt -y install containerd

# Post-install containerd config (systemd cgroups)
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Optional: silence crictl endpoint warnings (handy for your reset/diagnostics)
cat <<'EOF' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Make sure we're using legacy iptables (keep if this is what you've standardized on)
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy || true

# Install Kubernetes (v1.34)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt update
sudo apt -y install kubelet kubeadm kubectl etcd-client
sudo apt-mark hold kubelet kubeadm kubectl

mkdir -p ~/.kube

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Cilium CLI
CILIUM_CLI_VERSION="$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)"
CLI_ARCH=amd64
if [[ "$(uname -m)" == "aarch64" ]]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz"{,.sha256sum}
sha256sum --check "cilium-linux-${CLI_ARCH}.tar.gz.sha256sum"
sudo tar xzvfC "cilium-linux-${CLI_ARCH}.tar.gz" /usr/local/bin
rm -f "cilium-linux-${CLI_ARCH}.tar.gz"{,.sha256sum}

# Install Hubble CLI
HUBBLE_VERSION="$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)"
HUBBLE_ARCH=amd64
if [[ "$(uname -m)" == "aarch64" ]]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all \
  "https://github.com/cilium/hubble/releases/download/${HUBBLE_VERSION}/hubble-linux-${HUBBLE_ARCH}.tar.gz"{,.sha256sum}
sha256sum --check "hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum"
sudo tar xzvfC "hubble-linux-${HUBBLE_ARCH}.tar.gz" /usr/local/bin
rm -f "hubble-linux-${HUBBLE_ARCH}.tar.gz"{,.sha256sum}

echo
echo "=== Done. Docker not installed; containerd is configured and running. ==="
echo "Profile written to: /etc/default/k8s-node-profile"
echo "  CILIUM_KUBE_PROXY_REPLACEMENT=${ENABLE_CILIUM_KPR}"
