output "vpc_id" {
  description = "VPC ID"
  value       = try(module.vpc[0].vpc_id, null)
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = try(module.eks[0].cluster_name, null)
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = try(module.observability[0].grafana_url, null)
}

output "prometheus_url" {
  description = "Prometheus UI URL"
  value       = try(module.observability[0].prometheus_url, null)
}