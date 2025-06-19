#!/bin/bash

# Script to label all EKS nodes with cluster name
# Usage: ./label-nodes.sh <cluster-name>

# Check if cluster name argument is provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a cluster name as an argument"
    echo "Usage: $0 <cluster-name>"
    echo "Example: $0 agentless-demo"
    exit 1
fi

CLUSTER_NAME=$1

echo "Getting list of nodes..."
# Get all node names (excluding the header)
NODES=$(kubectl get nodes --no-headers -o custom-columns=":metadata.name")

if [ -z "$NODES" ]; then
    echo "Error: No nodes found or kubectl command failed"
    exit 1
fi

echo "Found the following nodes:"
echo "$NODES"
echo ""

echo "Labeling nodes with cluster name: $CLUSTER_NAME"
echo ""

# Loop through each node and apply the label
for NODE in $NODES; do
    echo "Labeling node: $NODE"
    kubectl label node "$NODE" "alpha.eksctl.io/cluster-name=$CLUSTER_NAME" --overwrite
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully labeled $NODE"
    else
        echo "✗ Failed to label $NODE"
    fi
    echo ""
done

echo "Node labeling completed!"
