read -r -p "Is this an OpenShift cluster? [y/N] " openshift_answer
openshift_answer="${openshift_answer:-N}"

if [[ "$openshift_answer" =~ ^[Yy]$ ]]; then
  helm upgrade --install illumio -f illumio-cven.yaml oci://quay.io/illumio/illumio --namespace illumio-system --create-namespace --server-side=false
else
  helm upgrade --install illumio -f illumio-cven.yaml oci://quay.io/illumio/illumio --namespace illumio-system --create-namespace
fi
