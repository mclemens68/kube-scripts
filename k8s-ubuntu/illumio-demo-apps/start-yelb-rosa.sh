#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="yelb"
APP_LABEL="app=yelb-ui"

echo "Starting yelb demo app"

oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

oc -n "$NAMESPACE" create serviceaccount yelb-sa --dry-run=client -o yaml | oc apply -f -

oc adm policy add-scc-to-user anyuid \
  -z yelb-sa \
  -n "$NAMESPACE"

oc apply -f yelb-rosa.yaml -n "$NAMESPACE"

echo
echo "Waiting for deployments to become ready..."
oc -n "$NAMESPACE" rollout status deployment/redis-server --timeout=180s
oc -n "$NAMESPACE" rollout status deployment/yelb-db --timeout=180s
oc -n "$NAMESPACE" rollout status deployment/yelb-appserver --timeout=180s
oc -n "$NAMESPACE" rollout status deployment/yelb-ui --timeout=180s

echo
echo "Services:"
oc get svc -n "$NAMESPACE"

echo
echo "Route:"
oc get route -n "$NAMESPACE"

ROUTE_HOST="$(oc get route yelb-ui -n "$NAMESPACE" -o jsonpath='{.spec.host}')"

if [[ -n "${ROUTE_HOST:-}" ]]; then
  echo
  echo "Yelb UI should be available at:"
  echo "http://${ROUTE_HOST}"
  echo

  echo "Testing HTTP response from route..."
  curl -I --max-time 15 "http://${ROUTE_HOST}" || true
else
  echo "Route host was not found."
fi

echo
echo "Pods:"
oc get pods -n "$NAMESPACE" -o wide

echo
echo "Done."
