#kubectl label nodes turingpi1 kubernetes.io/role=worker  
kubectl label nodes turingpi2 kubernetes.io/role=worker  
kubectl label nodes turingpi3 kubernetes.io/role=worker  
kubectl label nodes turingpi4 kubernetes.io/role=worker

#kubectl label nodes turingpi1 node-type=worker
kubectl label nodes turingpi2 node-type=worker
kubectl label nodes turingpi3 node-type=worker
kubectl label nodes turingpi4 node-type=worker
