#!/bin/bash

# Connect to EKS cluster
# Usage: ./02-connect-eks-cluster.sh <region> <cluster_name>

if [ $# -ne 2 ]; then
    echo "Error: Please provide both region and cluster name as arguments"
    echo "Usage: $0 <region> <cluster_name>"
    echo "Example: $0 us-east-1 clemens-eks-demo"
    exit 1
fi

REGION="$1"
CLUSTER_NAME="$2"
echo "Connecting to EKS cluster '$CLUSTER_NAME' in region '$REGION'"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
