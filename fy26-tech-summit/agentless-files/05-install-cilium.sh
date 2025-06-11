helm install cilium cilium/cilium --version 1.17.3 \
  --namespace kube-system \
  --set eni.enabled=true \
  --set ipam.mode=eni \
  --set egressMasqueradeInterfaces='^ens[0-9]+' \
  --set routingMode=native \
  --set kubeProxyReplacement=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true
