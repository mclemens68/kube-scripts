#!/bin/bash

NODES=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

for NODE_NAME in $NODES; do
  echo "=== Debugging node: $NODE_NAME ==="

  # Trigger debug pod (non-interactive)
  kubectl debug node/"$NODE_NAME" --image=busybox -- chroot /host ip a >/dev/null 2>&1 &

  # Give the API a few seconds to create the pod
  sleep 3

  # Find the actual pod name
  POD_NAME=$(kubectl get pods --no-headers \
    | awk -v node="$NODE_NAME" '$1 ~ ("^node-debugger-"node) {print $1}' \
    | sort | tail -n1)

  if [ -z "$POD_NAME" ]; then
    echo "  ❌ Could not find debug pod for $NODE_NAME"
    continue
  fi

  # Wait for the pod to be in Completed state or give up after 15s
  for i in {1..15}; do
    STATUS=$(kubectl get pod "$POD_NAME" -o jsonpath='{.status.phase}' 2>/dev/null)
    if [[ "$STATUS" == "Succeeded" || "$STATUS" == "Running" ]]; then
      break
    fi
    sleep 1
  done

  echo "  ✅ Debug pod: $POD_NAME"
  echo ""
  echo "  --- RAW ip a output ---"
  kubectl logs "$POD_NAME" 2>/dev/null || echo "  ❌ Failed to get logs for $POD_NAME"

  echo ""
  echo "  --- Parsed interface/IP info ---"
  kubectl logs "$POD_NAME" 2>/dev/null | awk '/^[0-9]+: / {iface=$2; sub(":", "", iface)} /inet / {print "  " iface, $2}'

  echo ""
  echo "  🔄 Cleaning up $POD_NAME"
  kubectl delete pod "$POD_NAME" >/dev/null 2>&1
  echo ""
done

