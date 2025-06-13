resource "kubernetes_namespace" "monitoring" {
  count = var.cluster_name != null ? 1 : 0
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  version    = "2.20.0" # Check for latest version

  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.ebs_csi_driver.arn
  }

  # Optional: If you need to specify the cluster name
  set {
    name  = "controller.clusterName"
    value = var.cluster_name
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name = "AmazonEKS_EBS_CSI_DriverRole_${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}


resource "kubernetes_storage_class" "ebs_sc" {
  metadata {
    name = "ebs-sc"
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }

  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  depends_on = [kubernetes_namespace.monitoring]
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
    storage_size    = var.observability_config.storage_size
  })]
}


resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "5.6.1"
  values     = [file("${path.module}/loki-values.yaml")]
  # values     = [templatefile("${path.module}/loki-values.yaml", {
    # retention_hours = var.observability_config.retention_hours
    # storage_size    = var.observability_config.storage_size
  # })]
  set {
    name  = "persistence.storageClassName"
    value = kubernetes_storage_class.ebs_sc.metadata[0].name
  }
  set {
    name  = "persistence.size"
    value = var.observability_config.storage_size
  }
  set {
    name  = "persistence.accessModes[0]"
    value = "ReadWriteOnce"
  }
  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "loki.limits_config.retention_period"
    value = "${var.observability_config.retention_hours}h"
  }
  set {
    name  = "loki.chunk_store_config.max_look_back_period"
    value = "${var.observability_config.retention_hours}h"
  }
  set {
    name  = "loki.storageConfig.bucketnames"
    value = "loki-bucket"  # Adjust as needed
  }

  depends_on = [kubernetes_storage_class.ebs_sc, kubernetes_namespace.monitoring]
  # Ensure Loki is created after the storage class and namespace
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

# Otel Collector
resource "helm_release" "otel_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  version    = "0.88.0"

  values = [
    templatefile("${path.module}/otel-values.yaml", {
      loki_endpoint = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      cluster_name = var.cluster_name
    })
  ]

  depends_on = [kubernetes_namespace.monitoring, helm_release.loki, helm_release.prometheus]
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

