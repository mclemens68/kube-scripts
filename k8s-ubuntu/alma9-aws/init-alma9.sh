# Update system and install essential packages
sudo dnf -y update
sudo dnf -y install vim git nc chrony

# Install Illumio VEN required packages
sudo dnf -y install bind-utils diffutils curl gawk gmp gzip libcap libnfnetlink net-tools nftables sed shadow-utils tar util-linux

# Set time zone
sudo timedatectl set-timezone America/Chicago

# Disable swap permanently
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo dnf -y remove dphys-swapfile
sudo rm -f /var/swap

# Load kernel modules for containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set kernel parameters for Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# Install Docker & containerd
sudo dnf -y remove docker* podman containerd runc
sudo dnf -y install dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo docker run hello-world

# Post-install containerd configuration
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# Install Kubernetes (v1.29)
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo dnf -y install kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable kubelet
sudo systemctl start kubelet
mkdir ~/.kube

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh

#Add Google server to DNS

# Find the UUID of the eth0 connection
CONNECTION_UUID=$(nmcli -t -f UUID,DEVICE connection show | grep "eth0" | cut -d: -f1)

# Check if the UUID was found
if [ -n "$CONNECTION_UUID" ]; then
    # Add the DNS server to the connection
    nmcli connection modify "$CONNECTION_UUID" ipv4.dns "8.8.8.8"

    # Restart NetworkManager to apply the changes
    systemctl restart NetworkManager
else
    echo "Error: No active connection found for eth0."
    exit 1
fi

