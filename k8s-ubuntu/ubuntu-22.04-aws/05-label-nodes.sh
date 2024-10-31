#kubectl label nodes k8s-mstr-u kubernetes.io/role=worker  
kubectl label nodes k8s-wk1-u.clemenslabs.com kubernetes.io/role=worker  
kubectl label nodes k8s-wk2-u.clemenslabs.com kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr-u node-type=worker
kubectl label nodes k8s-wk1-u.clemenslabs.com node-type=worker
kubectl label nodes k8s-wk2-u.clemenslabs.com node-type=worker
