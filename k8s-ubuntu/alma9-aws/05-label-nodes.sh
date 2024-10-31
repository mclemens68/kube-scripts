#kubectl label nodes k8s-mstr-a kubernetes.io/role=worker  
kubectl label nodes k8s-wk1-a.clemenslabs.com kubernetes.io/role=worker  
kubectl label nodes k8s-wk2-a.clemenslabs.com  kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr-a node-type=worker
kubectl label nodes k8s-wk1-a.clemenslabs.com node-type=worker
kubectl label nodes k8s-wk2-a.clemenslabs.com node-type=worker
