# Clean all docker containers and images
sudo docker system prune -af
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
ssh -t ec2-user@k8s-wk1-a-priv.clemenslabs.com '/home/ec2-user/reset.sh'
ssh -t ec2-user@k8s-wk2-a-priv.clemenslabs.com '/home/ec2-user/reset.sh'
ssh -t ec2-user@k8s-wk1-a-priv.clemenslabs.com 'sudo reboot'
ssh -t ec2-user@k8s-wk2-a-priv.clemenslabs.com 'sudo reboot'
# Reboot control node
sudo reboot
