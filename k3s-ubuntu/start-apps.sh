# start guestbook app
echo "Starting guestbook demo app"
kubectl apply -f guestbook/guestbook-illumio.yaml -n guestbook
# start yelb app
echo "Starting yelb demo app"
 kubectl apply -f yelb/deployments/platformdeployment/Kubernetes/yaml/yelb-k8s-loadbalancer-taefik-illumio.yaml -n yelb
# update frontend IP's and restart haproxy
sudo ./haproxy-cfg.sh
