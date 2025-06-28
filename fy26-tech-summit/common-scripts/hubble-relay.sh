#!/bin/bash

# --- Port-forward hubble-relay ---
echo "🚪 Port-forwarding Hubble Relay to localhost:4245..."

kubectl -n kube-system port-forward svc/hubble-relay 4245:80 >/dev/null 2>&1 &

echo "✅ You can now run: hubble observe --server localhost:4245"
