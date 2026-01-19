#!/bin/bash

echo "Upgrading Kubernetes from v1.29 to v1.34"
echo "=========================================="

# Update apt repository to v1.34
echo "Updating Kubernetes apt repository to v1.34..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Update apt cache
sudo apt update

# Unhold packages to allow upgrade
echo "Unholding Kubernetes packages..."
sudo apt-mark unhold kubelet kubeadm kubectl

# Upgrade packages
echo "Upgrading kubeadm..."
sudo apt install -y kubeadm

# Verify kubeadm version
echo "Verifying kubeadm version..."
kubeadm version

# Upgrade kubelet and kubectl
echo "Upgrading kubelet and kubectl..."
sudo apt install -y kubelet kubectl

# Hold packages again
echo "Holding Kubernetes packages..."
sudo apt-mark hold kubelet kubeadm kubectl

# Restart kubelet
echo "Restarting kubelet..."
sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo ""
echo "Upgrade complete!"
echo "Current versions:"
echo "  kubeadm: $(kubeadm version -o short)"
echo "  kubelet: $(kubelet --version)"
echo "  kubectl: $(kubectl version --client -o yaml | grep gitVersion)"
echo ""
echo "NOTE: You still need to run 'kubeadm upgrade apply v1.34.x' on the control plane"
echo "and 'kubeadm upgrade node' on worker nodes to complete the cluster upgrade."