#!/bin/bash

echo "Deleting Agentless Demo resources..."
kubectl delete -f agentless-demo.yaml

echo "Deleting Bank of Anthos microservices..."
kubectl delete -f ./bank-of-anthos/kubernetes-manifests -n bank-of-anthos

echo "Deleting Bank of Anthos JWT secret..."
kubectl delete -f ./bank-of-anthos/extras/jwt/jwt-secret.yaml -n bank-of-anthos

echo "🧹 Cleanup complete."

