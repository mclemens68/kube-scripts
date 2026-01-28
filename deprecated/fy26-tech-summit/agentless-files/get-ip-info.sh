#!/bin/bash

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

if [ -z "$NODE_NAME" ]; then
  echo "Error: Could not detect any nodes."
  exit 1
fi

# Start debug pod in the background (non-interactive)
kubectl debug node/"$NODE_NAME" --image=busybox -- chroot /host ip a >/dev/null 2>&1 &

# Wait a few seconds for the pod to start showing up
sleep 3

# Find the actual pod name (kubectl will name it itself)
POD_NAME=$(kubectl get pods --no-headers \
  | awk -v node="$NODE_NAME" '$1 ~ ("^node-debugger-"node) {print $1}' \
  | sort | tail -n1)

if [ -z "$POD_NAME" ]; then
  echo "Error: Could not find debug pod for $NODE_NAME"
  exit 1
fi

# Wait for it to be Ready or Completed
kubectl wait pod "$POD_NAME" --for=condition=Ready --timeout=15s >/dev/null 2>&1 || \
kubectl wait pod "$POD_NAME" --for=condition=ContainersReady --timeout=15s >/dev/null 2>&1 || \
sleep 5

echo "==== IP ADDR INFO ON $NODE_NAME ===="
kubectl logs "$POD_NAME"

echo ""
echo "==== PARSED IP ADDR ===="
kubectl logs "$POD_NAME" 2>/dev/null | awk '/^[0-9]+: / {iface=$2; sub(":", "", iface)} /inet / {print iface, $2}'

# Clean up
kubectl delete pod "$POD_NAME" >/dev/null 2>&1
