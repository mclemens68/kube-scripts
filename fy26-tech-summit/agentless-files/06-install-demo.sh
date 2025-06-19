#!/bin/bash

echo "🔐 Applying Bank of Anthos JWT secret..."
kubectl apply -f ./bank-of-anthos/extras/jwt/jwt-secret.yaml

echo "🏦 Deploying Bank of Anthos microservices..."
kubectl apply -f ./bank-of-anthos/kubernetes-manifests

echo "🚨 Deploying Agentless Demo (Bad Actor + MegaShop + Cilium Policy)..."
kubectl apply -f agentless-demo.yaml

echo "✅ All demo resources applied successfully."

