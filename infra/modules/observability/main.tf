resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

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
  count      = var.enable_prometheus ? 1 : 0
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "46.8.0"
  values     = [templatefile("${path.module}/prometheus-values.yaml", {
    retention_hours = var.observability_config.retention_hours
    storage_size    = var.observability_config.storage_size
  })]
  depends_on = [kubernetes_namespace.monitoring, kubernetes_storage_class.ebs_sc]
}

resource "helm_release" "loki" {
  count      = var.enable_loki ? 1 : 0
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "5.6.1"
  values     = [templatefile("${path.module}/loki-values.yaml", {
    retention_hours = var.observability_config.retention_hours
    storage_size    = var.observability_config.storage_size
  })]
  depends_on = [kubernetes_namespace.monitoring, kubernetes_storage_class.ebs_sc]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "6.57.3"
  values     = [file("${path.module}/grafana-values.yaml")]
  set_sensitive {
    name  = "adminUser"
    value = var.grafana_admin_user
  }
  set_sensitive {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
  depends_on = [helm_release.prometheus, helm_release.loki]
}

resource "helm_release" "otel_collector" {
  count      = var.enable_otel_collector ? 1 : 0
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "0.88.0"
  values = [
    templatefile("${path.module}/otel-values.yaml", {
      loki_endpoint = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
      cluster_name  = var.cluster_name
    })
  ]
  depends_on = [helm_release.loki, helm_release.prometheus]
}

resource "helm_release" "adot_collector" {
  count      = var.enable_adot_collector ? 1 : 0
  name       = "adot-collector"
  repository = "https://aws-observability.github.io/aws-otel-helm-charts"
  chart      = "adot-collector"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "0.37.0"
  values     = [file("${path.module}/adot-values.yaml")]
  depends_on = [kubernetes_namespace.monitoring]
}


resource "aws_iam_policy" "adot_cloudwatch_logs" {
  name        = "adot-cloudwatch-logs"
  description = "Allow ADOT Collector to push logs to CloudWatch"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adot_cloudwatch_logs" {
  role       = var.node_role_name
  policy_arn = aws_iam_policy.adot_cloudwatch_logs.arn
}

