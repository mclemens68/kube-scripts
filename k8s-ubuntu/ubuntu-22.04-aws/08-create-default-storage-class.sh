helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
kubectl apply -f gp3-sc.yaml
kubectl get storageclass
