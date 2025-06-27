#!/bin/bash

# Run init terraform before running the first time
# Usage: ./01-create-eks-cluster.sh <cluster_name>

if [ $# -eq 0 ]; then
    echo "Error: Please provide a cluster name as an argument"
    echo "Usage: $0 <cluster_name>"
    echo "Example: $0 clemens-eks-demo"
    exit 1
fi

CLUSTER_NAME="$1"
echo "Creating EKS cluster with name: $CLUSTER_NAME"

terraform apply -var="cluster_name=$CLUSTER_NAME"
