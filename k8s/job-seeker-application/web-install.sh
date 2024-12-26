#!/bin/bash

kubectl create -f ~/NT531/k8s/job-seeker-application/namespace.yaml
kubectl create -f ~/NT531/k8s/job-seeker-application/database 
kubectl create -f ~/NT531/k8s/job-seeker-application/backend
kubectl create -f ~/NT531/k8s/job-seeker-application/frontend

echo "Checking namespace main-application..."
kubectl get all -n main-application
