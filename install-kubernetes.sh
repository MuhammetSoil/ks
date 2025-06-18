#!/bin/bash

set -e

echo "[1/6] SWAP kapatılıyor..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[2/6] Docker kuruluyor..."
apt update -y
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

apt update -y
apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Docker için systemd cgroup driver ayarı
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl enable docker
systemctl daemon-reexec
systemctl restart docker

echo "[3/6] Kubernetes repository ekleniyor..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update -y

echo "[4/6] kubeadm, kubelet ve kubectl kuruluyor..."
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

echo "[5/6] Br_netfilter modülü etkinleştiriliyor..."
modprobe br_netfilter
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system

echo "[6/6] Kurulum tamamlandı."
echo "Şimdi bu node'u master yapmak için aşağıdaki komutu kullanabilirsiniz:"
echo ""
echo "  kubeadm init --pod-network-cidr=192.168.0.0/16"
echo ""
