# Elastic Kubernetes Cluster with Auto-scaling and Observability Stack

## Project Overview

This Terraform project provisions a Kubernetes cluster on AWS EKS with:
- Custom VPC networking infrastructure
- Auto-scaling at both cluster (CA) and pod (HPA) levels
- Comprehensive observability stack (metrics, logging, visualization)

## Architecture Diagram

![System Architecture](docs/diagrams/observability_eks_architecture.png)

## Key Components

### 1. Infrastructure Layer
- **Custom VPC** with public and private subnets across multiple AZs
- **EKS Cluster** with managed node groups
- **Auto-scaling** via Cluster Autoscaler and Horizontal Pod Autoscaler
- **Security** through IAM roles, security groups, and network policies

### 2. Observability Stack
- **Metrics**: Prometheus with node/pod exporters
- **Visualization**: Grafana with pre-configured dashboards
- **Logging**: Fluent Bit forwarding to Elasticsearch
- **Alerting**: Alertmanager with Slack/email notifications

### 3. Automation
- **Terraform** for infrastructure provisioning
- **GitHub Actions** for CI/CD pipelines
- **Helm** for Kubernetes package management

## Prerequisites

- AWS account with sufficient permissions
- Terraform v1.0+ installed
- kubectl configured

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/terraform-eks-observability.git
   cd terraform-eks-observability