
variable "aws_profile" {
  description = "The AWS profile to use for authentication"
  type        = string
  default     = "task" 
  
}
variable "environment" {
  description = "The environment for the resources (e.g., dev, staging, prod)"
  type        = string
  default     = "dev" 
}
variable "region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
  default     = "eu-west-1" 
}
variable "project_name" {
  description = "The name of the project for resource naming"
  type        = string
  default     = "jucr"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "100.100.0.0/16"
  
}

variable "node_instance_type" {
  description = "Instance type for the EKS node"
  type        = string
  default     = "t4g.small" # Example instance type, can be changed as needed
}




### EKS Specific Variables
variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}