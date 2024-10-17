#kubectl label nodes k8s-mstr kubernetes.io/role=worker  
kubectl label nodes k8s-wk1 kubernetes.io/role=worker  
kubectl label nodes k8s-wk2 kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr node-type=worker
kubectl label nodes k8s-wk1 node-type=worker
kubectl label nodes k8s-wk2 node-type=worker
