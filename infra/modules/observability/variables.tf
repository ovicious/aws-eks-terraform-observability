variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "enable_alb_controller" {
  description = "Whether to enable ALB controller"
  type        = bool
  default     = false
}

variable "alb_controller_role_arn" {
  description = "ARN of ALB controller IAM role"
  type        = string
  default     = null
}

variable "cluster_autoscaler_role_arn" {
  description = "ARN of cluster autoscaler IAM role"
  type        = string
  default     = null
}

variable "observability_config" {
  description = "Configuration for observability stack"
  type = object({
    storage_size    = string
    retention_hours = number
  })
  default = {
    storage_size    = "5Gi"
    retention_hours = 2
  }
}