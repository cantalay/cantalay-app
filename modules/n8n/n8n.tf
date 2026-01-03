# --------------------------------------------------
# NAMESPACE
# --------------------------------------------------
resource "kubernetes_namespace" "n8n" {
  metadata {
    name = "n8n"
  }
}

# --------------------------------------------------
# VAULT SECRETS
# --------------------------------------------------
data "vault_kv_secret_v2" "n8n" {
  mount = "kv"
  name  = "n8n"
}

data "vault_kv_secret_v2" "redis" {
  mount = "kv"
  name  = "redis"
}

# --------------------------------------------------
# HELM RELEASE
# --------------------------------------------------
resource "helm_release" "n8n" {
  name       = "n8n"
  repository = "https://community-charts.github.io/helm-charts"
  chart      = "n8n"
  version    = "1.16.13"

  namespace = kubernetes_namespace.n8n.metadata[0].name

  values = [
    file("${path.module}/values-n8n.yaml")
  ]

  timeout = 600
  atomic  = true

  set = [
    # ===============================
    # ENCRYPTION KEY (SECRET)
    # ===============================
    {
      name  = "extraEnvVars.N8N_ENCRYPTION_KEY"
      value = data.vault_kv_secret_v2.n8n.data["N8N_ENCRYPTION_KEY"]
    },

    # ===============================
    # POSTGRES (SECRET)
    # ===============================
    {
      name  = "externalPostgresql.host"
      value = data.vault_kv_secret_v2.n8n.data["POSTGRES_HOST"]
    },
    {
      name  = "externalPostgresql.username"
      value = data.vault_kv_secret_v2.n8n.data["POSTGRES_USER"]
    },
    {
      name  = "externalPostgresql.password"
      value = data.vault_kv_secret_v2.n8n.data["POSTGRES_PASSWORD"]
    },
    {
      name  = "externalPostgresql.database"
      value = data.vault_kv_secret_v2.n8n.data["POSTGRES_DB"]
    },

    # ===============================
    # REDIS (SECRET)
    # ===============================
    {
      name  = "externalRedis.host"
      value = data.vault_kv_secret_v2.n8n.data["REDIS_HOST"]
    },
    {
      name  = "externalRedis.username"
      value = "default"
    },
    {
      name  = "externalRedis.password"
      value = data.vault_kv_secret_v2.redis.data["REDIS_PASSWORD"]
    }
  ]
}
resource "null_resource" "n8n_dashboard_cert" {
  depends_on = [
    helm_release.n8n
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/n8n-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/n8n-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "n8n_dashboard_ingress" {
  depends_on = [
    null_resource.n8n_dashboard_cert
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/n8n-dashboard.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/n8n-dashboard.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "n8n_webhook_cert" {
  depends_on = [
    helm_release.n8n
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/webhook-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/webhook-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "n8n_webhook_ingress" {
  depends_on = [
    null_resource.n8n_webhook_cert
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/n8n-webhook.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/n8n-webhook.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}

