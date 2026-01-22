# Ensure cluster prefix is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
CLUSTER_PREFIX="$1"

# Label master as control-plane
kubectl label nodes ${CLUSTER_PREFIX}-mstr.clemenslabs.com node-type=control-plane --overwrite

# Label workers with custom node-type label
kubectl label nodes ${CLUSTER_PREFIX}-wk1.clemenslabs.com node-type=worker --overwrite
kubectl label nodes ${CLUSTER_PREFIX}-wk2.clemenslabs.com node-type=worker --overwrite

# Update ROLES label for worker nodes
kubectl label node ${CLUSTER_PREFIX}-wk1.clemenslabs.com node-role.kubernetes.io/worker= --overwrite
kubectl label node ${CLUSTER_PREFIX}-wk2.clemenslabs.com node-role.kubernetes.io/worker= --overwrite
