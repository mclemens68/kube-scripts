./02_setup.sh
./03-cni-flannel-helm.sh
./04-join.sh
./05-label-nodes.sh
scp /home/ubuntu/.kube/config k8s-client-priv.clemenslabs.com:/home/ubuntu/.kube/config
