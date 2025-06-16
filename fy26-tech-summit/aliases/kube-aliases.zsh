#Kubernetes
alias kube-nodes='kubectl get nodes -o wide'
alias kube-pods='kubectl get pods --all-namespaces -o wide'
alias kube-svc='kubectl get svc --all-namespaces -o wide'

# List all contexts
alias kube-ctx-list='kubectl config get-contexts'

# Show the current context
alias kube-ctx-current='kubectl config current-context'

# Use a context
kube-ctx-use() {
  if [ -z "$1" ]; then
    echo "Usage: kube-ctx-use <context-name>"
  else
    kubectl config use-context "$1"
  fi
}

# Delete a context
kube-ctx-delete() {
  if [ -z "$1" ]; then
    echo "Usage: kube-ctx-delete <context-name>"
  else
    kubectl config delete-context "$1"
  fi
}

alias kube-top-nodes='kubectl top nodes'
alias kube-top-pods='kubectl top pods -A --containers --sum'
alias kube-dns-test-internal='kubectl run busybox --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default.svc.cluster.local'
alias kube-dns-test-external='kubectl run busybox --image=busybox --restart=Never --rm -it -- nslookup google.com'
alias yelb-bash="kubectl exec -it -n yelb \$(kubectl get pods -n yelb -l app=yelb-appserver -o jsonpath='{.items[0].metadata.name}') -- /bin/bash"
alias kube-shell='kubectl run test-shell --image=busybox --rm -it --restart=Never'
