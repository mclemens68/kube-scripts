#kubectl label nodes k8s-mstr-a kubernetes.io/role=worker  
kubectl label nodes k8s-wk1-a kubernetes.io/role=worker  
kubectl label nodes k8s-wk2-a kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr-a node-type=worker
kubectl label nodes k8s-wk1-a node-type=worker
kubectl label nodes k8s-wk2-a node-type=worker
