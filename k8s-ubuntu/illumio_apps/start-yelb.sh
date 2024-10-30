# start yelb app
echo "Starting yelb demo app"
 kubectl apply -f yelb/deployments/platformdeployment/Kubernetes/yaml/yelb-k8s-loadbalancer-taefik-illumio.yaml -n yelb
