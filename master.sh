#!/bin/bash

set -euxo pipefail

PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR="10.0.0.0/8"

sudo kubeadm config images pull --cri-socket=unix:///var/run/crio/crio.sock

if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then

    MASTER_PRIVATE_IP=$(ip addr show ens33 | awk '/inet / {print $2}' | cut -d/ -f1)
    sudo kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --apiserver-cert-extra-sans="$MASTER_PRIVATE_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap --cri-socket=unix:///var/run/crio/crio.sock

elif [[ "$PUBLIC_IP_ACCESS" == "true" ]]; then

    MASTER_PUBLIC_IP=$(curl ifconfig.me && echo "")
    sudo kubeadm init --control-plane-endpoint="$MASTER_PUBLIC_IP" --apiserver-cert-extra-sans="$MASTER_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap --cri-socket=unix:///var/run/crio/crio.sock

else
    echo "Error: MASTER_PUBLIC_IP has an invalid value: $PUBLIC_IP_ACCESS"
    exit 1
fi

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
