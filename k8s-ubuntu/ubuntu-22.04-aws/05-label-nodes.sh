#kubectl label nodes k8s-mstr kubernetes.io/role=worker  
kubectl label nodes k8s-wk1.clemenslabs.com kubernetes.io/role=worker  
kubectl label nodes k8s-wk2.clemenslabs.com kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr node-type=worker
kubectl label nodes k8s-wk1.clemenslabs.com node-type=worker
kubectl label nodes k8s-wk2.clemenslabs.com node-type=worker
