# Copy this file to illumio-k3s.yaml and update the below info
# pce_url in the format of fqdn:port
pce_url: poc3.illum.io:443 
# cluster_id and cluster_token are copied from the pce when the container cluster is created
cluster_id: 7bb8d978-2cbc-4ea1-97b7-33b5a7f76e6b
cluster_token: 3997712_38e000bfc9677550a484e81714be7102d138a955616860fb133454960d76468d
# cluster_code is the pairing key from the pce for your kubernetes nodes
cluster_code: 1bb5c5c59c9f37472dd340ebe2589e4fe0c6a51aad510aac8d99476d256101fe461cfe067f8328573
containerRuntime: k3s_containerd
containerManager: kubernetes
ignore_cert: false
