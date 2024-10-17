# Add Traefik repository to Helm, uncomment the first time 
helm repo add traefik https://traefik.github.io/charts

# Check the added repository
helm search repo traefik

# Install Traefik
helm upgrade --install traefik traefik/traefik --create-namespace \
--namespace traefik-v2 --wait

#kubectl port-forward $(kubectl get pods -n traefik-v2 --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000
