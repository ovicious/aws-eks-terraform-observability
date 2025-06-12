variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  type        = string
}

variable "node_role_name" {
  description = "Name of the EKS node IAM role"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "instance_types" {
  description = "Instance types for worker nodes"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired worker nodes count"
  type        = number
}

variable "max_capacity" {
  description = "Maximum worker nodes count"
  type        = number
}

variable "min_capacity" {
  description = "Minimum worker nodes count"
  type        = number
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string

}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  type        = string
}

