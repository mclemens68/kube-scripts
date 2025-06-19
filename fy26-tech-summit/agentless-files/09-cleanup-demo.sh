#!/bin/bash

echo "Deleting Agentless Demo resources..."
kubectl delete -f agentless-demo.yaml

echo "Deleting Bank of Anthos microservices..."
kubectl delete -f ./bank-of-anthos/kubernetes-manifests

echo "Deleting Bank of Anthos JWT secret..."
kubectl delete -f ./bank-of-anthos/extras/jwt/jwt-secret.yaml

echo "🧹 Cleanup complete."

