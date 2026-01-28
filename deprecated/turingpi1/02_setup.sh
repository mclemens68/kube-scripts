sudo kubeadm init --config kubeadm-config.yaml
#sudo kubeadm init --pod-network-cidr=10.244.0.0/16
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Uncommennt to allow pods to be able to run on control plane node
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-
