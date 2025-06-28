#!/bin/bash

set -e

echo "🔧 Installing essential Kubernetes + Terraform tools on AWS CloudShell..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# --- kubectl ---
if ! command -v kubectl &> /dev/null; then
  echo "📦 Installing kubectl..."
  KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi
echo "✅ kubectl: $(kubectl version --client --output=yaml | grep gitVersion || echo installed)"

# --- Helm ---
if ! command -v helm &> /dev/null; then
  echo "🎛️ Installing Helm..."
  HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name)
  curl -LO https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
  tar -zxf helm-${HELM_VERSION}-linux-amd64.tar.gz
  sudo mv linux-amd64/helm /usr/local/bin/
fi
echo "✅ helm: $(helm version --short || echo installed)"

# --- Cilium CLI ---
if ! command -v cilium &> /dev/null; then
  echo "🕸️ Installing Cilium CLI..."
  curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
  tar -xzf cilium-linux-amd64.tar.gz
  sudo mv cilium /usr/local/bin/
fi
echo "✅ cilium: $(cilium version | grep cilium-cli || echo installed)"

# --- Hubble CLI ---
if ! command -v hubble &> /dev/null; then
  echo "🔭 Installing Hubble CLI..."
  curl -LO https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
  tar -xzf hubble-linux-amd64.tar.gz
  sudo mv hubble /usr/local/bin/
fi
echo "✅ hubble: $(hubble version || echo installed)"

# --- Terraform ---
if ! command -v terraform &> /dev/null; then
  echo "🏗️ Installing Terraform..."
  TF_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r .tag_name | sed 's/^v//')
  curl -LO https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
  unzip -o terraform_${TF_VERSION}_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
fi
echo "✅ terraform: $(terraform version | head -n 1)"

# --- Cleanup ---
echo "🧹 Cleaning up..."
cd ~
rm -rf "$TMP_DIR"

echo "🎉 All tools installed and ready to go!"

