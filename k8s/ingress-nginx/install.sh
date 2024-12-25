#!/bin/bash

helm upgrade --install myingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "name": "http",
        "port": 80,
        "nodePort": 30080
      },
      {
        "name": "https",
        "port": 443,
        "nodePort": 30443
      }
    ]
  }
}'

kubectl patch deploy ingress-nginx-controller -n ingress-nginx -p '{
  "spec": {
    "replicas": 3
  }
}'