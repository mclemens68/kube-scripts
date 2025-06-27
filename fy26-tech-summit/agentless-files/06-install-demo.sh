#!/bin/bash

echo "� Creating bank-of-anthos namespace..."
kubectl create namespace bank-of-anthos --dry-run=client -o yaml | kubectl apply -f -

echo "�🔐 Applying Bank of Anthos JWT secret..."
kubectl apply -f ./bank-of-anthos/extras/jwt/jwt-secret.yaml -n bank-of-anthos

echo "🏦 Deploying Bank of Anthos microservices..."
kubectl apply -f ./bank-of-anthos/kubernetes-manifests -n bank-of-anthos

echo "🚨 Deploying Agentless Demo (Bad Actor + MegaShop + Cilium Policy)..."
kubectl apply -f agentless-demo.yaml

echo "✅ All demo resources applied successfully."

