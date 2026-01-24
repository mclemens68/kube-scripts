# start yelb app
echo "Starting yelb demo app"
 kubectl apply -f yelb-k8s-aws-lb.yaml -n yelb --create-namespace
