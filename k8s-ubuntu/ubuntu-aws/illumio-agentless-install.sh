#!/bin/bash

# Note. If Cilium and Hubble are installed in a namespace other than 'kube-system',
# ensure that the Illumio Cloud Operator has access to that namespace by adding the
# additional namespaces to the onboarding credentials YAML file like the following example:
#
# cilium:
#   namespaces:
#     - kube-system
#     - cilium

# Check if a filename argument was passed
if [ -z "$1" ]; then
  echo "Usage: $0 <illumio-cloud-operator-onboarding-credentials.yaml> <version>"
  echo "Example: $0 illumio-cloud-operator-values.yaml v1.3.11"
  exit 1
fi

# Check if version argument was passed
if [ -z "$2" ]; then
  echo "Usage: $0 <illumio-cloud-operator-onboarding-credentials.yaml> <version>"
  echo "Example: $0 illumio-cloud-operator-values.yaml v1.3.11"
  exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
  echo "Error: File '$1' not found."
  exit 1
fi

# Run the helm install command
helm install illumio -f "$1" --namespace illumio-cloud oci://ghcr.io/illumio/charts/cloud-operator --version "$2" --create-namespace
