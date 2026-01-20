#!/bin/bash

# Get the region from AWS metadata or set it explicitly
REGION="us-east-1"

# Function to get instance ID by hostname
get_instance_id() {
    local hostname=$1
    aws ec2 describe-instances \
        --region $REGION \
        --profile se15 \
        --filters "Name=tag:Name,Values=$hostname" "Name=instance-state-name,Values=running" \
        --query 'Reservations[0].Instances[0].[InstanceId,Placement.AvailabilityZone]' \
        --output text
}

# Get availability zone for the region (e.g., us-east-1a)
# You can hardcode this or detect it
AZ="${REGION}a"

echo "Setting providerIDs for cluster nodes..."

# Wait for nodes to be ready
sleep 10

# Get node names
MASTER_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')
WORKER_NODES=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')

# Set providerID for master
if [ -n "$MASTER_NODE" ]; then
    HOSTNAME=$(echo $MASTER_NODE | cut -d'.' -f1)
    INSTANCE_INFO=$(get_instance_id $HOSTNAME)
    INSTANCE_ID=$(echo $INSTANCE_INFO | awk '{print $1}')
    INSTANCE_AZ=$(echo $INSTANCE_INFO | awk '{print $2}')
    
    if [ -n "$INSTANCE_ID" ]; then
        echo "Setting providerID for $MASTER_NODE: aws:///$INSTANCE_AZ/$INSTANCE_ID"
        kubectl patch node $MASTER_NODE -p "{\"spec\":{\"providerID\":\"aws:///$INSTANCE_AZ/$INSTANCE_ID\"}}"
    fi
fi

# Set providerID for workers
for NODE in $WORKER_NODES; do
    HOSTNAME=$(echo $NODE | cut -d'.' -f1)
    INSTANCE_INFO=$(get_instance_id $HOSTNAME)
    INSTANCE_ID=$(echo $INSTANCE_INFO | awk '{print $1}')
    INSTANCE_AZ=$(echo $INSTANCE_INFO | awk '{print $2}')
    
    if [ -n "$INSTANCE_ID" ]; then
        echo "Setting providerID for $NODE: aws:///$INSTANCE_AZ/$INSTANCE_ID"
        kubectl patch node $NODE -p "{\"spec\":{\"providerID\":\"aws:///$INSTANCE_AZ/$INSTANCE_ID\"}}"
    fi
done

echo "Verifying providerIDs..."
kubectl get nodes -o custom-columns=NAME:.metadata.name,PROVIDER-ID:.spec.providerID
