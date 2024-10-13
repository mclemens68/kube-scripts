kubectl delete ns illumio-system
helm install illumio -f illumio-k3s.yaml oci://quay.io/illumio/illumio --namespace illumio-system --create-namespace --version 4.3.0
