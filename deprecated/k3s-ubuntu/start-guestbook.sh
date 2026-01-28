# start guestbook app
echo "Starting guestbook demo app"
kubectl apply -f guestbook/guestbook-illumio.yaml -n guestbook
# update frontend IP's and restart haproxy
sudo ./haproxy-cfg.sh
