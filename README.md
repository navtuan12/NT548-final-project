# K8sMasterDeploy

## Project Description

K8sMasterDeploy is a comprehensive solution for deploying a Kubernetes multi-master cluster on AWS. This project also includes setting up a CI/CD pipeline using Jenkins, GitHub Actions, and GitOps. Additionally, it provides monitoring and logging capabilities using Prometheus and Grafana.

## Features

- Deploy Kubernetes multi-master cluster on AWS
- Setup CI/CD pipeline using Jenkins, GitHub Actions, and GitOps
- Monitoring and logging with Prometheus and Grafana

## Prerequisites

- AWS account
- Basic knowledge of Kubernetes
- Jenkins, GitHub Actions, and GitOps familiarity
- Prometheus and Grafana understanding

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/K8sMasterDeploy.git
cd K8sMasterDeploy
```

### Step 2: Setup AWS Environment

- Configure your AWS CLI with the necessary credentials.
- Create an S3 bucket and an IAM role for Kubernetes.

### Step 3: Deploy Kubernetes Cluster

- Use the provided Terraform scripts to deploy the Kubernetes multi-master cluster.

```bash
cd terraform
terraform init
terraform apply
```

### Step 4: Setup CI/CD Pipeline

- Configure Jenkins and GitHub Actions using the provided configuration files.
- Integrate GitOps for continuous deployment.

### Step 5: Setup Monitoring and Logging

- Deploy Prometheus and Grafana using the provided Helm charts.

```bash
helm install prometheus stable/prometheus
helm install grafana stable/grafana
```

## Usage

1. Access the Kubernetes cluster using `kubectl`.

```bash
kubectl get nodes
```

2. Monitor the cluster using Prometheus and Grafana.

3. Use Jenkins and GitHub Actions for CI/CD.
