#!/bin/bash

# Run init terraform before running the first time
# Usage: ./01-create-eks-cluster.sh <cluster_name> [s3_bucket_arn]

if [ $# -eq 0 ]; then
    echo "Error: Please provide a cluster name as an argument"
    echo "Usage: $0 <cluster_name> [s3_bucket_arn]"
    echo "Example: $0 clemens-eks-demo"
    echo "Example with VPC Flow Logs: $0 clemens-eks-demo arn:aws:s3:::my-flow-logs-bucket"
    exit 1
fi

CLUSTER_NAME="$1"
S3_BUCKET_ARN="$2"

if [ -n "$S3_BUCKET_ARN" ]; then
    echo "Creating EKS cluster with name: $CLUSTER_NAME and VPC Flow Logs to S3: $S3_BUCKET_ARN"
    terraform apply -var="cluster_name=$CLUSTER_NAME" -var="vpc_flow_logs_s3_arn=$S3_BUCKET_ARN"
else
    echo "Creating EKS cluster with name: $CLUSTER_NAME (no VPC Flow Logs)"
    terraform apply -var="cluster_name=$CLUSTER_NAME"
fi
