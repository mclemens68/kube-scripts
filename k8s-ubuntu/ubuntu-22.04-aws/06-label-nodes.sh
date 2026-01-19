# Label master as control-plane
kubectl label nodes k8s-mstr.clemenslabs.com node-type=control-plane --overwrite

# Label workers with custom node-type label
kubectl label nodes k8s-wk1.clemenslabs.com node-type=worker --overwrite
kubectl label nodes k8s-wk2.clemenslabs.com node-type=worker --overwrite

# Update ROLES label for worker nodes
kubectl label node k8s-wk1.clemenslabs.com node-role.kubernetes.io/worker= --overwrite
kubectl label node k8s-wk2.clemenslabs.com node-role.kubernetes.io/worker= --overwrite
