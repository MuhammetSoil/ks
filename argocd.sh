# Argo Cd Kurulum

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30007}]}}'

kubectl get svc -n argocd

#!/bin/bash

# Nginx konfigürasyon dosyasına ArgoCD reverse proxy ayarlarını ekliyoruz
NGINX_CONF="/etc/nginx/sites-available/kubernetes"

# Sunucunun IP adresini alıyoruz (Burada kullanmak istediğiniz IP adresini otomatik alabilirsiniz)
SERVER_IP=$(hostname -I | awk '{print $1}')  # Bu komut, sunucunun ilk IP adresini alır

# ArgoCD için reverse proxy yapılandırmasını ekliyoruz
cat <<EOL | sudo tee -a $NGINX_CONF > /dev/null
server {
    listen 80;
    server_name $SERVER_IP;  # Sunucu IP adresi burada kullanılıyor

    location / {
        proxy_pass http://$SERVER_IP:30007;  # NodePort servisine yönlendirme
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Eğer Kubernetes kendi kendine imzalı sertifika kullanıyorsa SSL doğrulamasını devre dışı bırakmak için
        proxy_ssl_verify off;
    }
}
EOL

# Nginx yapılandırmasını test ediyoruz
sudo nginx -t

# Nginx servisini yeniden başlatıyoruz
sudo systemctl restart nginx
