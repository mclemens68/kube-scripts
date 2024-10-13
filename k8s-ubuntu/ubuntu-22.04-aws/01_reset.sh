# Clean all docker containers and images
docker system prune -af
# Reset kubernetes cluster
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
rm -rf ~/.kube/*
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X
sudo nft flush ruleset
# Reset and reboot nodes
ssh -t ubuntu@k8s-wk1-priv.clemenslabs.com '/home/ubuntu/reset.sh'
ssh -t ubuntu@k8s-wk2-priv.clemenslabs.com '/home/ubuntu/reset.sh'
ssh -t ubuntu@k8s-wk1-priv.clemenslabs.com 'sudo reboot'
ssh -t ubuntu@k8s-wk2-priv.clemenslabs.com 'sudo reboot'
# Reboot control node
sudo reboot
