#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <FQDN> <AWS_PROFILE>"
    exit 1
fi

FQDN="$1"
AWS_PROFILE="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the edge route with the custom hostname
echo "Creating edge route 'yelb-custom' with hostname ${FQDN}..."
oc create route edge yelb-custom \
  --service=yelb-ui \
  --port=80 \
  --hostname="${FQDN}" \
  --insecure-policy=Allow \
  -n yelb

# Print all routes in the yelb namespace
echo ""
echo "All routes in yelb namespace:"
oc get routes -n yelb

# Grab the default (auto-generated) OpenShift route hostname — any route other than yelb-custom
DEFAULT_ROUTE_HOST=$(oc get routes -n yelb --no-headers | grep -v "yelb-custom" | head -1 | awk '{print $2}')

if [ -z "$DEFAULT_ROUTE_HOST" ]; then
    echo "Error: Could not find a default route to ping for IP resolution."
    exit 1
fi

echo ""
echo "Resolving IP address for default route (${DEFAULT_ROUTE_HOST})..."
IP_ADDRESS=$(dig +short "${DEFAULT_ROUTE_HOST}" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)

if [ -z "$IP_ADDRESS" ]; then
    echo "Error: Could not resolve IP for ${DEFAULT_ROUTE_HOST}."
    exit 1
fi

echo "Resolved IP: ${IP_ADDRESS}"

# Check if a DNS record already exists and delete it if so
echo ""
echo "Checking if Route53 A record already exists for ${FQDN}..."
ZONE_NAME=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "${ZONE_NAME}." \
    --profile "${AWS_PROFILE}" \
    --query "HostedZones[?Name==\`${ZONE_NAME}.\`].Id" \
    --output text | cut -d'/' -f3)

if [ -n "$HOSTED_ZONE_ID" ]; then
    EXISTING_RECORD=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$HOSTED_ZONE_ID" \
        --query "ResourceRecordSets[?Name==\`${FQDN}.\` && Type=='A']" \
        --profile "${AWS_PROFILE}" \
        --output json)

    if [ "$EXISTING_RECORD" != "[]" ]; then
        echo "Existing A record found for ${FQDN}. Deleting..."
        "${SCRIPT_DIR}/../../common-scripts/delete-route53-record.sh" "${FQDN}" "${AWS_PROFILE}"
    else
        echo "No existing A record found for ${FQDN}."
    fi
else
    echo "Warning: Could not look up hosted zone for ${ZONE_NAME}. Skipping pre-delete check."
fi

# Create the Route53 DNS record
echo ""
echo "Creating Route53 A record: ${FQDN} -> ${IP_ADDRESS}..."
"${SCRIPT_DIR}/../../common-scripts/create-route53-record.sh" "${IP_ADDRESS}" "${FQDN}" "${AWS_PROFILE}"
