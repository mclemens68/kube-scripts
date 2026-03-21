# start yelb app
echo "Starting yelb demo app"
kubectl create namespace yelb --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f yelb-eks-aks.yaml -n yelb
