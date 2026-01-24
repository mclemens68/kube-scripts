kubectl delete ns illumio-system
helm upgrade --install illumio -f illumio-k8s.yaml oci://quay.io/illumio/illumio --namespace illumio-system --create-namespace
