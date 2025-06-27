#!/bin/bash

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <IP_ADDRESS> <FQDN> <AWS_PROFILE>"
    exit 1
fi

IP_ADDRESS="$1"
FQDN="$2"
AWS_PROFILE="$3"

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

# Generate a change batch JSON
CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Create A record for $FQDN",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$FQDN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP_ADDRESS"
          }
        ]
      }
    }
  ]
}
EOF
)

# Submit the change
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "$CHANGE_BATCH" \
    --profile "$AWS_PROFILE"

echo "✅ A record for $FQDN -> $IP_ADDRESS created in zone $ZONE_NAME (ID: $HOSTED_ZONE_ID) using profile $AWS_PROFILE"
