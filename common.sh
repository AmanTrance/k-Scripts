#!/bin/bash

sudo kubeadm reset 
sudo apt-get purge kubeadm kubectl kubelet cri-o || true 
sudo apt-get autoremove
sudo rm -rf /etc/kubernetes || true 
sudo rm -rf /root/.kube || true 

sudo ntpdate time.nist.gov

set -euxo pipefail

KUBERNETES_VERSION="v1.32"
CRIO_VERSION="v1.32"

sudo swapoff -a

(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "CRI runtime installed successfully"

curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -yf kubelet kubectl kubeadm
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt-get update -y

sudo apt-get install -y jq

local_ip="$(ip --json addr show ens33 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"

cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
