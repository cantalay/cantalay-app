resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}

data "vault_kv_secret_v2" "redis" {
  mount = "kv"
  name  = "redis"
}

resource "helm_release" "redis" {
  name       = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "redis"
  version    = "24.1.0"

  namespace = kubernetes_namespace.redis.metadata[0].name

  values = [
    file("${path.module}/values-redis.yaml")
  ]

  timeout = 600
  atomic  = true

  set = [
    {
      name  = "auth.password"
      value = data.vault_kv_secret_v2.redis.data["REDIS_PASSWORD"]
    }
  ]
}
