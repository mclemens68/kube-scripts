# Ensure cluster prefix is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
export CLUSTER_PREFIX="$1"

# Render kubeadm config with the provided cluster prefix and initialize
envsubst < ./kubeadm-config.yaml > /tmp/kubeadm-config.yaml
kubeadm init --config /tmp/kubeadm-config.yaml

#sudo kubeadm init --pod-network-cidr=10.244.0.0/16
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Uncommennt to allow pods to be able to run on control plane node
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-
