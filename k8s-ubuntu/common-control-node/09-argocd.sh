#create namespace  
kubectl create namespace argocd  
#Install as on any other cluster  
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Save ArgoCD password to local file argocd-pw.txt
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-pw.txt

# Set ArgoCD UI to IP address 192.168.1.3
kubectl patch service argocd-server -n argocd --patch '{ "spec": { "type": "LoadBalancer", "loadBalancerIP": "192.168.1.3" } }'
