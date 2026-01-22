# Ensure cluster prefix is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
CLUSTER_PREFIX="$1"

./02_setup.sh "$CLUSTER_PREFIX"
./03-cni-flannel-helm.sh
./04-join.sh "$CLUSTER_PREFIX"
./05-label-nodes.sh "$CLUSTER_PREFIX"
scp /home/ubuntu/.kube/config ${CLUSTER_PREFIX}-client-priv.clemenslabs.com:/home/ubuntu/.kube/config
