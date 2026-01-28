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
ssh -t matt@turingpi2 '/home/matt/reset.sh'
ssh -t matt@turingpi3 '/home/matt/reset.sh'
ssh -t matt@turingpi4 '/home/matt/reset.sh'
ssh -t matt@turingpi2 'sudo reboot'
ssh -t matt@turingpi3 'sudo reboot'
ssh -t matt@turingpi4 'sudo reboot'
# Reboot control node
sudo reboot
