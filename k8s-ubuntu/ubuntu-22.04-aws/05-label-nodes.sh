#kubectl label nodes k8s-mstr-u kubernetes.io/role=worker  
kubectl label nodes k8s-wk1-u kubernetes.io/role=worker  
kubectl label nodes k8s-wk2-u kubernetes.io/role=worker  

#kubectl label nodes k8s-mstr-u node-type=worker
kubectl label nodes k8s-wk1-u node-type=worker
kubectl label nodes k8s-wk2-u node-type=worker
