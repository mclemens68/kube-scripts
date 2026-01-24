# Ensure cluster prefix is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <cluster-prefix>"
  exit 1
fi
CLUSTER_PREFIX="$1"

./02-setup-cilium-kube-proxy-replacement.sh "$CLUSTER_PREFIX"
./03-cni-cilium-kube-proxy-replacement.sh
./04-join.sh "$CLUSTER_PREFIX"
./05-set-provider-ids.sh
./06-label-nodes.sh "$CLUSTER_PREFIX"
./07-install-aws-loadbalancer.sh
./08-create-default-storage-class.sh
./09-disable-kube-proxy.sh
scp /home/ubuntu/.kube/config ${CLUSTER_PREFIX}-client-priv.clemenslabs.com:/home/ubuntu/.kube/config
