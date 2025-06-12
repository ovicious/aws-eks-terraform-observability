resource "kubernetes_namespace" "monitoring" {
  count = var.cluster_name != null ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_persistent_volume_claim" "observability_storage" {
  count = var.cluster_name != null ? 1 : 0
  metadata {
    name      = "observability-storage"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "gp2"
    resources {
      requests = {
        storage = var.observability_config.storage_size
      }
    }
  }
  depends_on = [kubernetes_namespace.monitoring] # Add this line
}

resource "helm_release" "prometheus" {
  count      = var.cluster_name != null ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "46.8.0"
  
  values = [templatefile("${path.module}/prometheus-values.yaml", {
    retention_hours = var.observability_config.retention_hours
  })]
}


resource "helm_release" "loki" {
  count      = var.cluster_name != null ? 1 : 0
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "5.6.1"
  values     = [templatefile("${path.module}/loki-values.yaml", {
    retention_hours = var.observability_config.retention_hours
  })]

  depends_on = [kubernetes_persistent_volume_claim.observability_storage]
}

resource "helm_release" "grafana" {
  count      = var.cluster_name != null ? 1 : 0
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "6.57.3"
  values     = [file("${path.module}/grafana-values.yaml")]

  set_sensitive {
    name  = var.grafana_admin_user
    value = var.grafana_admin_password
  }

  depends_on = [helm_release.prometheus, helm_release.loki]
}

# Conditional ALB Controller Installation
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_alb_controller ? 1 : 0  # ← Only install if enabled
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.alb_controller_role_arn  # ← Pass this from root module
  }

  depends_on = [kubernetes_namespace.monitoring]
}