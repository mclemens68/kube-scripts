# Add repo to helm  
# helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/  
# Install  
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
--set nfs.server=192.168.1.125 \
--set nfs.path=/data \
--create-namespace \
--namespace nfs-system
