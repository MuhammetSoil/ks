#!/bin/bash

# ArgoCD için gerekli Namespace ve kurulum
echo "ArgoCD kurulumu başlatılıyor..."

# ArgoCD namespace oluşturuluyor
kubectl create namespace argocd

# ArgoCD kurulum dosyasını uyguluyoruz
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD server'ını NodePort olarak ayarlıyoruz
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30007}]}}'

# ArgoCD servislerini kontrol ediyoruz
kubectl get svc -n argocd

# Nginx Reverse Proxy Yapılandırması için konfigürasyon dosyasını belirliyoruz
NGINX_CONF="/etc/nginx/sites-available/kubernetes"

# Sunucunun IP adresini alıyoruz (Eğer IP adresi sabitse, burada manuel olarak yazabilirsiniz)
SERVER_IP=$(hostname -I | awk '{print $1}')  # Sunucunun ilk IP adresini alıyoruz

# ArgoCD için Reverse Proxy yapılandırmasını Nginx dosyasına ekliyoruz
echo "Nginx yapılandırması ekleniyor..."

cat <<EOL | sudo tee $NGINX_CONF > /dev/null
server {
    listen 80;
    server_name $SERVER_IP;  # Sunucu IP adresi burada kullanılıyor (Alternatif olarak alan adı da yazabilirsiniz)

    location / {
        proxy_pass http://$SERVER_IP:30007;  # NodePort servisine yönlendirme
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Eğer Kubernetes kendi kendine imzalı sertifika kullanıyorsa, SSL doğrulamasını devre dışı bırakıyoruz
        proxy_ssl_verify off;
    }
}
EOL

# Nginx yapılandırmasını test ediyoruz
echo "Nginx yapılandırması test ediliyor..."
sudo nginx -t

# Nginx servisini yeniden başlatıyoruz
echo "Nginx servisi yeniden başlatılıyor..."
sudo systemctl restart nginx
