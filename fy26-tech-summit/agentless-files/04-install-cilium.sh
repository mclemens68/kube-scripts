helm install cilium cilium/cilium --version 1.17.3 \
  --namespace kube-system \
  --set cni.chainingMode=aws-cni \
  --set cni.exclusive=false \
  --set enableIPv4Masquerade=false \
  --set routingMode=native \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true