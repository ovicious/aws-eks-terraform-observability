variable "enable_vpc" {
  description = "Enable VPC module"
  type        = bool
  default     = false
}

variable "enable_eks" {
  description = "Enable EKS module"
  type        = bool
  default     = false
}

variable "enable_iam" {
  description = "Enable IAM module"
  type        = bool
  default     = false
}

variable "enable_observability" {
  description = "Enable Observability module"
  type        = bool
  default     = false
}

variable "env_name" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "demo-project"
}
variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "avi"
}
variable "infra_version" {
  description = "Version of the infrastructure"
  type        = string
  default     = "1.0.0"
}
variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "task"

}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "instance_types" {
  description = "EKS worker node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}
variable "node_disk_size" {
  description = "EKS worker node disk size in GB"
  type        = number
  default     = 20
}

variable "desired_capacity" {
  description = "EKS worker node desired count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "EKS worker node minimum count"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "EKS worker node maximum count"
  type        = number
  default     = 3
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.31"
}

variable "observability_storage_size" {
  description = "Storage size for observability stack"
  type        = string
  default     = "5Gi"
}

variable "observability_retention_hours" {
  description = "Retention hours for observability stack"
  type        = number
  default     = 2
}
variable "grafana_admin_user" {
  description = "Grafana admin user"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
}

variable "enable_alb_controller" {
  description = "Whether to deploy AWS Load Balancer Controller"
  type        = bool
  default     = false # Disabled by default
}

