# Note this assumes your network interface is ens5
# You can verify this interface is present by running one of:
# get-ip-info.sh - gets network info on the first node in the cluster
# get-ip-info-all.sh - gets network info on all nodes in the cluster
helm install cilium cilium/cilium --version 1.17.3 \
  --namespace kube-system \
  --set eni.enabled=true \
  --set ipam.mode=eni \
  --set egressMasqueradeInterfaces=ens5 \
  --set routingMode=native \
  --set kubeProxyReplacement=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true
