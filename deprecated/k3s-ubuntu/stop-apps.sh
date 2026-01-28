# stop guestbook app
echo "Stopping guestbook demo app"
kubectl delete -f guestbook/guestbook-illumio.yaml -n guestbook
# stop yelb app
echo "Stopping yelb demo app"
kubectl delete -f yelb/deployments/platformdeployment/Kubernetes/yaml/yelb-k8s-loadbalancer-taefik-illumio.yaml -n yelb
