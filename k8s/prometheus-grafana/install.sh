#!/bin/bash

git clone https://github.com/prometheus-operator/kube-prometheus.git

mv grafana-ingress.yaml kube-prometheus/manifests/grafana-ingress.yaml

kubectl create -f kube-prometheus/manifests/setup
kubectl create -f kube-prometheus/manifests
