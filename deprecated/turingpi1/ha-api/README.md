# Turing Pi HA Kubernetes API VIP

This setup provides a highly available Kubernetes API endpoint using:

- `HAProxy` for TCP load balancing
- `Keepalived` for a floating virtual IP (VIP)
- VIP address: `192.168.1.210`
- Kubernetes API endpoint:
  - `turingpi-api.clemenshome.com`
  - `192.168.1.210:16443`

This design avoids conflicts with the local kube-apiserver already listening on `:6443` on each control-plane node.

The VIP listens on `:16443` and forwards traffic to the local Kubernetes API servers on `:6443`.

Control plane nodes:

| Host | IP |
|---|---|
| turingpi1 | 192.168.1.201 |
| turingpi2 | 192.168.1.202 |
| turingpi3 | 192.168.1.203 |

Worker node:

| Host | IP |
|---|---|
| turingpi4 | 192.168.1.204 |

---

# 1. DNS

Create a DNS override:

```text
turingpi-api.clemenshome.com -> 192.168.1.210
```

If using OPNsense + AdGuard + Unbound:

- Ensure the override exists in the resolver actually answering DNS queries
- Restart the DNS service if changes do not immediately apply
- Verify with:

```bash
dig @192.168.1.1 +short turingpi-api.clemenshome.com
```

Expected:

```text
192.168.1.210
```

---

# 2. Install packages on ALL control plane nodes

Run on:

- turingpi1
- turingpi2
- turingpi3

```bash
sudo apt update
sudo apt install -y haproxy keepalived
```

---

# 3. Repository layout

Recommended repo structure:

```text
ha-api/
├── README.md
├── haproxy.cfg
├── check_apiserver.sh
├── keepalived.conf.turingpi1
├── keepalived.conf.turingpi2
└── keepalived.conf.turingpi3
```

---

# 4. Enable non-local bind on ALL control plane nodes

This allows HAProxy to bind to the VIP even when the node does not currently own the address.

Run on ALL control plane nodes:

```bash
echo 'net.ipv4.ip_nonlocal_bind = 1' | \
sudo tee /etc/sysctl.d/99-haproxy-nonlocal-bind.conf

sudo sysctl --system
```

Verify:

```bash
cat /proc/sys/net/ipv4/ip_nonlocal_bind
```

Expected:

```text
1
```

---

# 5. HAProxy configuration

File:

```text
haproxy.cfg
```

Contents:

```cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 2048

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    timeout connect 5s
    timeout client 50s
    timeout server 50s

frontend kubernetes-api
    bind 192.168.1.210:16443
    mode tcp
    option tcplog
    default_backend kubernetes-api-backend

backend kubernetes-api-backend
    mode tcp
    option tcp-check
    balance roundrobin

    server turingpi1 192.168.1.201:6443 check
    server turingpi2 192.168.1.202:6443 check
    server turingpi3 192.168.1.203:6443 check
```

---

# 6. API health check script

File:

```text
check_apiserver.sh
```

Contents:

```bash
#!/bin/bash

curl -k https://127.0.0.1:6443/readyz \
  >/dev/null 2>&1
```

Make executable:

```bash
chmod +x check_apiserver.sh
```

---

# 7. Keepalived configuration

## turingpi1

File:

```text
keepalived.conf.turingpi1
```

Contents:

```cfg
global_defs {
    router_id turingpi1
}

vrrp_script check_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8sha
    }

    virtual_ipaddress {
        192.168.1.210/24
    }

    track_script {
        check_apiserver
    }
}
```

---

## turingpi2

File:

```text
keepalived.conf.turingpi2
```

Contents:

```cfg
global_defs {
    router_id turingpi2
}

vrrp_script check_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8sha
    }

    virtual_ipaddress {
        192.168.1.210/24
    }

    track_script {
        check_apiserver
    }
}
```

---

## turingpi3

File:

```text
keepalived.conf.turingpi3
```

Contents:

```cfg
global_defs {
    router_id turingpi3
}

vrrp_script check_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 2
    weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 99
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass k8sha
    }

    virtual_ipaddress {
        192.168.1.210/24
    }

    track_script {
        check_apiserver
    }
}
```

---

# 8. Copy configs into /etc

Run on EACH control plane node.

## Create directories

```bash
sudo mkdir -p /etc/haproxy /etc/keepalived
```

---

## Copy HAProxy config

```bash
sudo cp haproxy.cfg /etc/haproxy/haproxy.cfg
```

---

## Copy node-specific Keepalived config

### On turingpi1

```bash
sudo cp keepalived.conf.turingpi1 \
  /etc/keepalived/keepalived.conf
```

### On turingpi2

```bash
sudo cp keepalived.conf.turingpi2 \
  /etc/keepalived/keepalived.conf
```

### On turingpi3

```bash
sudo cp keepalived.conf.turingpi3 \
  /etc/keepalived/keepalived.conf
```

---

## Copy health check script

```bash
sudo cp check_apiserver.sh \
  /etc/keepalived/check_apiserver.sh
```

---

## Set ownership and permissions

```bash
sudo chown root:root \
  /etc/haproxy/haproxy.cfg \
  /etc/keepalived/keepalived.conf \
  /etc/keepalived/check_apiserver.sh

sudo chmod 644 \
  /etc/haproxy/haproxy.cfg \
  /etc/keepalived/keepalived.conf

sudo chmod 755 \
  /etc/keepalived/check_apiserver.sh
```

---

# 9. Enable and start services

Run on ALL control plane nodes:

```bash
sudo systemctl enable --now haproxy keepalived

sudo systemctl reset-failed haproxy

sudo systemctl restart haproxy keepalived
```

---

# 10. Validation

## Validate HAProxy config

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

Expected:

```text
Configuration file is valid
```

---

## Validate HAProxy listener

```bash
sudo ss -ltnp | grep 16443
```

Expected:

```text
LISTEN ... 192.168.1.210:16443
```

---

## Validate API access through VIP

```bash
curl -k https://192.168.1.210:16443/readyz
```

Expected:

```text
ok
```

---

## Validate DNS endpoint

```bash
curl -k https://turingpi-api.clemenshome.com:16443/readyz
```

Expected:

```text
ok
```

---

## Validate all HA services

```bash
for n in turingpi1 turingpi2 turingpi3; do
  echo "===== $n ====="
  ssh $n '
    hostname
    ip addr show eth0 | grep 192.168.1.210 || true
    cat /proc/sys/net/ipv4/ip_nonlocal_bind
    systemctl is-active haproxy keepalived
    sudo ss -ltnp | grep 16443 || true
  '
done
```

Expected:

- Only ONE node owns the VIP
- All nodes:
  - have `ip_nonlocal_bind=1`
  - have active HAProxy
  - have active Keepalived
  - are listening on `192.168.1.210:16443`

---

# 11. Update kubeconfig

Update kubeconfig to use the HA VIP endpoint:

```bash
kubectl config set-cluster kubernetes \
  --server=https://turingpi-api.clemenshome.com:16443
```

Validate:

```bash
kubectl get nodes
```

---

# 12. Update kubeadm configuration

The cluster kubeadm configuration should reference:

```text
turingpi-api.clemenshome.com:16443
```

in:

```yaml
controlPlaneEndpoint:
```

Example:

```yaml
controlPlaneEndpoint: turingpi-api.clemenshome.com:16443
```

---

# 13. Join scripts

All future kubeadm join operations should use:

```text
turingpi-api.clemenshome.com:16443
```

Example worker join:

```bash
kubeadm join turingpi-api.clemenshome.com:16443 ...
```

Example control-plane join:

```bash
kubeadm join turingpi-api.clemenshome.com:16443 \
  --control-plane \
  --certificate-key ...
```

---

# 14. Failure testing

## Determine current VIP owner

```bash
for n in turingpi1 turingpi2 turingpi3; do
  echo "===== $n ====="
  ssh $n 'ip addr show eth0 | grep 192.168.1.210 || true'
done
```

Only one node should own the VIP.

---

## Reboot active VIP node

```bash
sudo reboot
```

Within a few seconds:

- another control-plane node should acquire the VIP
- Kubernetes API access through the VIP should continue functioning

Validate:

```bash
curl -k https://turingpi-api.clemenshome.com:16443/readyz
```

Expected:

```text
ok
```

---

# 15. Notes

- The Kubernetes API servers continue listening locally on `:6443`
- HAProxy provides the HA VIP listener on `:16443`
- This avoids conflicts with kube-apiserver binding to `:6443`
- This design allows:
  - HA kubectl access
  - HA worker joins
  - HA control-plane joins
  - HA GitOps integrations
  - HA automation/API access

Current verified status:

- HAProxy active on all 3 control-plane nodes
- Keepalived active on all 3 control-plane nodes
- VIP floating correctly
- DNS resolving correctly
- kubectl operating through HA VIP endpoint
- Cluster healthy
