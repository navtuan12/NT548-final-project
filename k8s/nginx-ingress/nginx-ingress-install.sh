#!/bin/bash

kubectl create namespace ingress-nginx # Tạo namespace cho Ingress

# Triển khai Nginx Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Kiểm tra trạng thái của Ingress Controller
echo "Checking the status of Nginx Ingress Controller pods..."
kubectl get pods --namespace ingress-nginx
