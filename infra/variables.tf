variable "environment" {
  description = "The environment for the resources (e.g., dev, staging, prod)"
  type        = string

}
variable "region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
}
variable "project_name" {
  description = "The name of the project for resource naming"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "100.100.0.0/16"
  
}
