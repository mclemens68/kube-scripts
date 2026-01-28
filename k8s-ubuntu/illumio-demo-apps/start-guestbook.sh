# start guestbook app
echo "Starting guestbook demo app"
kubectl create namespace guestbook --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f guestbook/guestbook-illumio.yaml -n guestbook
