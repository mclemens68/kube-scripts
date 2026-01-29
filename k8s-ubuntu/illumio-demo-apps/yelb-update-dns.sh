#!/usr/bin/env bash
set -euo pipefail

# yelb-update-dns.sh
#
# Usage:
#   ./yelb-update-dns.sh <CLUSTER_PREFIX> <DOMAIN_NAME> <AWS_PROFILE>
#
# Example:
#   ./yelb-update-dns.sh k8s2 clemenslabs.com se15
#
# What it does:
# - Reads the LoadBalancer hostname from svc/yelb-ui in namespace yelb
# - Waits (up to 5 minutes) for it to resolve to an IPv4 address
# - Deletes the existing Route53 A record for yelb.<CLUSTER_PREFIX>.<DOMAIN_NAME>
# - Creates/Upserts the Route53 A record pointing at the resolved IPv4 address

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <CLUSTER_PREFIX> <DOMAIN_NAME> <AWS_PROFILE>"
  exit 1
fi

CLUSTER_PREFIX="$1"
DOMAIN_NAME="$2"
AWS_PROFILE="$3"

FQDN="yelb.${CLUSTER_PREFIX}.${DOMAIN_NAME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DELETE_SCRIPT="${SCRIPT_DIR}/../../common-scripts/delete-route53-record.sh"
CREATE_SCRIPT="${SCRIPT_DIR}/../../common-scripts/create-route53-record.sh"

if [[ ! -x "${DELETE_SCRIPT}" ]]; then
  echo "Error: delete script not found or not executable: ${DELETE_SCRIPT}"
  exit 2
fi
if [[ ! -x "${CREATE_SCRIPT}" ]]; then
  echo "Error: create script not found or not executable: ${CREATE_SCRIPT}"
  exit 2
fi

echo "🔎 Looking up LoadBalancer hostname for yelb/yelb-ui..."
LB_HOSTNAME="$(kubectl -n yelb get svc yelb-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"

# If AWS ever returns IP directly (rare, but possible), capture it too
LB_IP_DIRECT="$(kubectl -n yelb get svc yelb-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

if [[ -n "${LB_IP_DIRECT}" ]]; then
  IP_ADDRESS="${LB_IP_DIRECT}"
  echo "✅ Service already has an external IP: ${IP_ADDRESS}"
else
  if [[ -z "${LB_HOSTNAME}" ]]; then
    echo "⚠️  LoadBalancer hostname not assigned yet (svc/yelb-ui). Will wait up to 5 minutes..."
  else
    echo "✅ LoadBalancer hostname: ${LB_HOSTNAME}"
  fi

  echo "⏳ Waiting up to 5 minutes for the LB to resolve to an IPv4 address..."
  end=$((SECONDS + 300))
  IP_ADDRESS=""

  while [[ ${SECONDS} -lt ${end} ]]; do
    # Refresh hostname each loop in case it was empty initially
    LB_HOSTNAME="$(kubectl -n yelb get svc yelb-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
    LB_IP_DIRECT="$(kubectl -n yelb get svc yelb-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

    if [[ -n "${LB_IP_DIRECT}" ]]; then
      IP_ADDRESS="${LB_IP_DIRECT}"
      break
    fi

    if [[ -n "${LB_HOSTNAME}" ]]; then
      # Prefer getent if present, fallback to dig
      if command -v getent >/dev/null 2>&1; then
        IP_ADDRESS="$(getent ahostsv4 "${LB_HOSTNAME}" 2>/dev/null | awk '{print $1}' | head -n1 || true)"
      elif command -v dig >/dev/null 2>&1; then
        IP_ADDRESS="$(dig +short A "${LB_HOSTNAME}" 2>/dev/null | head -n1 || true)"
      else
        echo "Error: neither 'getent' nor 'dig' is available to resolve DNS."
        exit 3
      fi

      if [[ -n "${IP_ADDRESS}" ]]; then
        break
      fi
    fi

    sleep 5
  done

  if [[ -z "${IP_ADDRESS}" ]]; then
    echo "❌ Timed out after 5 minutes waiting for yelb-ui LoadBalancer to resolve to an IP."
    echo "   Last seen hostname: ${LB_HOSTNAME:-<none>}"
    exit 4
  fi

  echo "✅ Resolved ${LB_HOSTNAME} -> ${IP_ADDRESS}"
fi

echo
echo "🧹 Deleting existing Route53 A record (if present): ${FQDN}"
"${DELETE_SCRIPT}" "${FQDN}" "${AWS_PROFILE}"

echo
echo "📝 Creating/Upserting Route53 A record: ${FQDN} -> ${IP_ADDRESS}"
"${CREATE_SCRIPT}" "${IP_ADDRESS}" "${FQDN}" "${AWS_PROFILE}"

echo
echo "✅ Done. ${FQDN} now points to ${IP_ADDRESS} (profile: ${AWS_PROFILE})"
