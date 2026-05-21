#!/bin/bash
set -euo pipefail

helm repo add traefik https://traefik.github.io/charts || true
helm repo update

helm upgrade --install traefik traefik/traefik \
  --create-namespace \
  --namespace traefik-v2 \
  --wait
