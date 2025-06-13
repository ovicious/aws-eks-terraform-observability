terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "helm" {
  kubernetes {
    host                   = try(module.eks[0].cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), "")
    token                  = try(module.eks[0].cluster_auth_token, "")
  }
}

provider "kubernetes" {
  host                   = try(module.eks[0].cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks[0].cluster_certificate_authority_data), "")
  token                  = try(module.eks[0].cluster_auth_token, "")
}

locals {
  common_tags = {
    Environment = var.env_name
    Project     = var.project_name
    Owner       = var.owner
    CreatedAt   = timestamp()
    Version     = var.infra_version
  }
}

module "vpc" {
  count      = var.enable_vpc ? 1 : 0
  source     = "./modules/vpc"
  env_name   = var.env_name
  aws_region = var.aws_region
  tags       = local.common_tags
}

module "iam" {
  count    = var.enable_iam ? 1 : 0
  source   = "./modules/iam"
  env_name = var.env_name
}

module "eks" {
  count              = var.enable_eks ? 1 : 0
  source             = "./modules/eks"
  aws_profile        = var.aws_profile
  env_name           = var.env_name
  vpc_id             = try(module.vpc[0].vpc_id, null)
  private_subnet_ids = try(module.vpc[0].private_subnet_ids, null)
  public_subnet_ids  = try(module.vpc[0].public_subnet_ids, null)
  cluster_role_name  = try(module.iam[0].eks_cluster_role_name, null)
  node_role_name     = try(module.iam[0].eks_node_role_name, null)
  cluster_role_arn   = try(module.iam[0].eks_cluster_role_arn, null)
  node_role_arn      = try(module.iam[0].eks_node_role_arn, null)
  instance_types     = var.instance_types
  node_disk_size     = var.node_disk_size
  desired_capacity   = var.desired_capacity
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  cluster_version    = var.cluster_version
}

module "observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./modules/observability"
  env_name          = var.env_name
  cluster_name      = try(module.eks[0].cluster_name, null)
  oidc_provider_arn = try(module.eks[0].oidc_provider_arn, null)
  oidc_provider_url = try(module.eks[0].oidc_provider_url, null)
  region            = var.aws_region

  enable_alb_controller       = var.enable_alb_controller
  alb_controller_role_arn     = try(module.iam[0].alb_controller_role_arn, null)
  cluster_autoscaler_role_arn = try(module.iam[0].cluster_autoscaler_role_arn, null)

  observability_config = {
    storage_size           = var.observability_storage_size
    retention_hours        = var.observability_retention_hours
  }
  grafana_admin_password = var.grafana_admin_password
  grafana_admin_user     = var.grafana_admin_user
  enable_prometheus      = var.enable_prometheus
  enable_loki            = var.enable_loki
  enable_otel_collector = var.enable_otel_collector
  enable_adot_collector  = var.enable_adot_collector
  node_role_name         = try(module.iam[0].eks_node_role_name, null)
  depends_on = [module.eks]
}
