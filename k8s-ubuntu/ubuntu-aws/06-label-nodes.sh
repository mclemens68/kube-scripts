#!/usr/bin/env bash
set -euo pipefail

# Ensure cluster prefix is provided
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <cluster-prefix> [region]"
  echo "  If [region] is omitted, the script will auto-detect AWS region via IMDS (falls back to 'AWS')."
  exit 1
fi

CLUSTER_PREFIX="$1"

detect_aws_region_imdsv2() {
  # Returns region like "us-east-1" if running on EC2 with IMDSv2 available; otherwise returns empty.
  local token az
  token="$(curl -sS --max-time 2 -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null || true)"

  if [[ -z "${token}" ]]; then
    return 1
  fi

  az="$(curl -sS --max-time 2 -H "X-aws-ec2-metadata-token: ${token}" \
    "http://169.254.169.254/latest/meta-data/placement/availability-zone" 2>/dev/null || true)"

  if [[ -z "${az}" ]]; then
    return 1
  fi

  # Strip trailing AZ letter: us-east-1a -> us-east-1
  printf '%s\n' "${az%[a-z]}"
}

# Region precedence:
#  1) explicit CLI arg
#  2) IMDSv2-derived AWS region (e.g., us-east-1)
#  3) fallback "AWS"
REGION="${2:-}"
if [[ -z "${REGION}" ]]; then
  if REGION_DETECTED="$(detect_aws_region_imdsv2)"; then
    REGION="${REGION_DETECTED}"
  else
    REGION="AWS"
  fi
fi

MASTER="${CLUSTER_PREFIX}-mstr.clemenslabs.com"
WK1="${CLUSTER_PREFIX}-wk1.clemenslabs.com"
WK2="${CLUSTER_PREFIX}-wk2.clemenslabs.com"

echo "Labeling nodes with topology region..."
echo "  topology.kubernetes.io/region=${REGION}"

# Topology region label
kubectl label node "$MASTER" topology.kubernetes.io/region="${REGION}" --overwrite
kubectl label node "$WK1"    topology.kubernetes.io/region="${REGION}" --overwrite
kubectl label node "$WK2"    topology.kubernetes.io/region="${REGION}" --overwrite

echo "Applying existing node-type / role labels..."

# Label master as control-plane
kubectl label node "$MASTER" node-type=control-plane --overwrite

# Label workers with custom node-type label
kubectl label node "$WK1" node-type=worker --overwrite
kubectl label node "$WK2" node-type=worker --overwrite

# Update ROLES label for worker nodes
kubectl label node "$WK1" node-role.kubernetes.io/worker= --overwrite
kubectl label node "$WK2" node-role.kubernetes.io/worker= --overwrite

echo "Node labeling complete."

echo "Verification:"
kubectl get nodes \
  -L topology.kubernetes.io/region \
  -L node-type
