#!/bin/bash
set -euo pipefail

kubectl label node turingpi1 node-type=control-plane --overwrite
kubectl label node turingpi2 node-type=control-plane --overwrite
kubectl label node turingpi3 node-type=control-plane --overwrite
kubectl label node turingpi4 node-type=worker --overwrite

kubectl label node turingpi3 storage=nfs --overwrite
