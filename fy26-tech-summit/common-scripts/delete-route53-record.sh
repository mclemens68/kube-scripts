#!/bin/bash

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <FQDN> <AWS_PROFILE>"
    exit 1
fi

FQDN="$1"
AWS_PROFILE="$2"

# Extract the zone name from the FQDN (e.g., sub.domain.com -> domain.com)
ZONE_NAME=$(echo "$FQDN" | awk -F. '{print $(NF-1)"."$NF}')

# Lookup the hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$ZONE_NAME." \
    --profile "$AWS_PROFILE" \
    --query "HostedZones[?Name==\`${ZONE_NAME}.\`].Id" \
    --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
    echo "Error: Hosted zone for $ZONE_NAME not found."
    exit 2
fi

# Get the existing A record for the FQDN
RECORD=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query "ResourceRecordSets[?Name==\`${FQDN}.\` && Type=='A']" \
    --profile "$AWS_PROFILE" \
    --output json)

if [ "$RECORD" == "[]" ]; then
    echo "No A record found for $FQDN in zone $ZONE_NAME."
    exit 0
fi

# Extract IP address(es) from the record set
VALUES=$(echo "$RECORD" | jq -r '.[0].ResourceRecords[].Value')

# Build the delete change batch
CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Delete A record for $FQDN",
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "$FQDN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          $(echo "$VALUES" | awk '{print "{\"Value\": \"" $1 "\"},"}' | sed '$ s/,$//')
        ]
      }
    }
  ]
}
EOF
)

# Submit the deletion request
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "$CHANGE_BATCH" \
    --profile "$AWS_PROFILE"

echo "🗑️ A record for $FQDN deleted from zone $ZONE_NAME (ID: $HOSTED_ZONE_ID) using profile $AWS_PROFILE"
