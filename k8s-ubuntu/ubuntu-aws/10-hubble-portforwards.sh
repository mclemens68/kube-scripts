#!/usr/bin/env bash
set -euo pipefail

# Sets up local port-forwards to Hubble UI + Hubble Relay.
# - Hubble UI:   http://localhost:12000
# - Hubble Relay: localhost:4245 (for hubble observe)

NS="${CILIUM_NAMESPACE:-cilium}"

echo "Waiting for Hubble components to be ready (ns: $NS)..."
kubectl -n "$NS" rollout status deploy/hubble-relay --timeout=10m
kubectl -n "$NS" rollout status deploy/hubble-ui --timeout=10m
echo "✅ Hubble Relay/UI are ready."

# Best-effort cleanup of prior forwards (ignore errors)
pkill -f "kubectl -n ${NS} port-forward svc/hubble-ui 12000:80" 2>/dev/null || true
pkill -f "kubectl -n ${NS} port-forward svc/hubble-relay 4245:80" 2>/dev/null || true

echo "🚪 Port-forwarding Hubble UI to http://localhost:12000 ..."
kubectl -n "$NS" port-forward svc/hubble-ui 12000:80 >/dev/null 2>&1 &
PF_UI_PID=$!

echo "🚪 Port-forwarding Hubble Relay to localhost:4245 ..."
kubectl -n "$NS" port-forward svc/hubble-relay 4245:80 >/dev/null 2>&1 &
PF_RELAY_PID=$!

echo
echo "✅ Hubble UI:    http://localhost:12000"
echo "✅ Hubble Relay: localhost:4245"
echo "   Example: hubble observe --server localhost:4245"
echo
echo "Port-forward PIDs: UI=${PF_UI_PID}, Relay=${PF_RELAY_PID}"
echo "Tip: to stop them: kill ${PF_UI_PID} ${PF_RELAY_PID}"
