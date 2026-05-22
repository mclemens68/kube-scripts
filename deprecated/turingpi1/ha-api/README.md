# Kubernetes API High Availability VIP

This setup provides a highly available Kubernetes API endpoint for the Turing Pi cluster using:

- keepalived (VRRP VIP failover)
- HAProxy (TCP load balancing)
- Virtual IP (VIP): `192.168.1.210`
- DNS Name: `turingpi-api.clemenshome.com`

The VIP will automatically move between control-plane nodes if one fails.

---

# Architecture

```text
kubectl
   |
   v
turingpi-api.clemenshome.com
   |
   v
192.168.1.210 (VIP)
   |
   v
HAProxy on active control-plane node
   |
   +--> 192.168.1.201:6443 (turingpi1)
   +--> 192.168.1.202:6443 (turingpi2)
   +--> 192.168.1.203:6443 (turingpi3)
```

---

# Prerequisites

- Existing working kubeadm cluster
- 3 control-plane nodes:
  - turingpi1 = 192.168.1.201
  - turingpi2 = 192.168.1.202
  - turingpi3 = 192.168.1.203
- `eth0` is the primary interface on all nodes
- kube-apiserver already listening on port 6443

---

# Install Packages

Run on ALL control-plane nodes:

```bash
sudo apt update
sudo apt install -y haproxy keepalived
```

---

# Create Config Files

## HAProxy

Copy `haproxy.cfg` to:

```text
/etc/haproxy/haproxy.cfg
```

## keepalived

Copy the matching file for each node:

| Node | Config File |
|---|---|
| turingpi1 | keepalived.conf.turingpi1 |
| turingpi2 | keepalived.conf.turingpi2 |
| turingpi3 | keepalived.conf.turingpi3 |

Destination:

```text
/etc/keepalived/keepalived.conf
```

## Health Check Script

Copy:

```text
check_apiserver.sh
```

To:

```text
/etc/keepalived/check_apiserver.sh
```

Make executable:

```bash
sudo chmod +x /etc/keepalived/check_apiserver.sh
```

---

# Enable Services

Run on ALL control-plane nodes:

```bash
sudo systemctl enable --now haproxy keepalived
sudo systemctl restart haproxy keepalived
```

---

# Verify VIP Ownership

One node should own the VIP:

```bash
ip addr show eth0 | grep 192.168.1.210
```

---

# Test API Reachability

From any node or workstation:

```bash
nc -vz 192.168.1.210 6443
```

Expected:

```text
Connection to 192.168.1.210 6443 port [tcp/*] succeeded!
```

Also test:

```bash
curl -k https://192.168.1.210:6443/readyz
```

Expected:

```text
ok
```

---

# Configure DNS

Create a DNS override / A record:

```text
turingpi-api.clemenshome.com -> 192.168.1.210
```

Verify:

```bash
dig turingpi-api.clemenshome.com
```

---

# Update kubeconfig (Optional)

If desired, point kubectl at the HA endpoint:

```bash
kubectl config set-cluster kubernetes \
  --server=https://turingpi-api.clemenshome.com:6443
```

Verify:

```bash
kubectl get nodes
```

---

# Test Failover

Determine VIP owner:

```bash
ip addr show eth0 | grep 192.168.1.210
```

Then stop keepalived on that node:

```bash
sudo systemctl stop keepalived
```

Verify VIP moves to another control-plane node:

```bash
ip addr show eth0 | grep 192.168.1.210
```

Confirm cluster still works:

```bash
kubectl get nodes
```

Restart keepalived afterward:

```bash
sudo systemctl start keepalived
```
