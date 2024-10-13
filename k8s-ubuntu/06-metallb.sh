# Add MetalLB repository to Helm, uncomment the first time 
# helm repo add metallb https://metallb.github.io/metallb

# Check the added repository
helm search repo metallb

# Create metallb-system namespace
kubectl apply -f metallb-ns.yaml

# Install MetalLB
helm install metallb metallb/metallb --namespace metallb-system --wait

kubectl apply -f metallb.yaml
