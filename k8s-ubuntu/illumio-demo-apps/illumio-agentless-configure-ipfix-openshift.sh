#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

log() {
  echo "[$SCRIPT_NAME] $*"
}

err() {
  echo "[$SCRIPT_NAME] ERROR: $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

confirm() {
  echo
  read -rp "Proceed with the above actions? [Y/n]: " RESPONSE
  RESPONSE=${RESPONSE:-Y}
  if [[ ! "$RESPONSE" =~ ^[Yy]$ ]]; then
    log "Aborted by user."
    exit 0
  fi
}

require_cmd oc

echo
echo "============================================================"
echo "Steps to configure IPFIX network flow export"
echo "============================================================"
echo
echo "export COLLECTOR_CLUSTER_IP=\$(oc get service -l app=cloud-operator -n illumio-cloud --template '{{(index .items 0).spec.clusterIP}}')"
echo
echo "oc patch network.operator cluster --type merge -p '{\"spec\":{\"exportNetworkFlows\":{\"ipfix\":{\"collectors\":[\"'\$COLLECTOR_CLUSTER_IP':4739\"]}}}}'"
echo
echo "oc get network.operator cluster -o jsonpath=\"{.spec.exportNetworkFlows}\""
echo
echo
echo "The output should be:"
echo
echo "{\"ipfix\":{\"collectors\":[\"<cloud-operator-cluster-ip>:4739\"]}}"
echo
echo "============================================================"
echo

confirm

log "Checking OpenShift login..."
if ! oc whoami >/dev/null 2>&1; then
  err "Not logged into OpenShift. Run 'oc login' first."
  exit 1
fi

log "Checking that the illumio-cloud namespace exists..."
oc get namespace illumio-cloud >/dev/null 2>&1 || {
  err "Namespace 'illumio-cloud' not found. Install the Illumio cloud operator first."
  exit 1
}

log "Checking that the cloud-operator service exists..."
oc get service -l app=cloud-operator -n illumio-cloud >/dev/null 2>&1 || {
  err "No service found with label app=cloud-operator in namespace illumio-cloud."
  exit 1
}

log "Resolving collector ClusterIP..."
export COLLECTOR_CLUSTER_IP="$(oc get service -l app=cloud-operator -n illumio-cloud --template '{{(index .items 0).spec.clusterIP}}')"

if [[ -z "${COLLECTOR_CLUSTER_IP}" || "${COLLECTOR_CLUSTER_IP}" == "<no value>" ]]; then
  err "Failed to resolve collector ClusterIP."
  exit 1
fi

log "Patching network.operator cluster..."
oc patch network.operator cluster --type merge -p '{"spec":{"exportNetworkFlows":{"ipfix":{"collectors":["'"$COLLECTOR_CLUSTER_IP"':4739"]}}}}'

log "Verifying exportNetworkFlows..."
RESULT="$(oc get network.operator cluster -o jsonpath="{.spec.exportNetworkFlows}")"

echo
echo "Configured exportNetworkFlows:"
echo "${RESULT}"
echo

EXPECTED="{\"ipfix\":{\"collectors\":[\"${COLLECTOR_CLUSTER_IP}:4739\"]}}"

if [[ "${RESULT}" == "${EXPECTED}" ]]; then
  log "Verification successful."
else
  log "Verification differs from expected."
  log "Expected: ${EXPECTED}"
  log "Actual:   ${RESULT}"
fi
