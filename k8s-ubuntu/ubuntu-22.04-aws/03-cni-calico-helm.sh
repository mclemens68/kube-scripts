# Needs manual creation of namespace to avoid helm error
kubectl create ns tigera-operator
#This is leftover from flannel recommendation, not sure if needed for calico
#kubectl label --overwrite ns tigera-operator pod-security.kubernetes.io/enforce=privileged

#helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator --version v3.26.3 --namespace tigera-operator
