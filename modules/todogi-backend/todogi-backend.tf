resource "kubernetes_namespace" "todogi_backend" {
  metadata {
    name = "todogi-backend"
  }
}
data "vault_kv_secret_v2" "todogi_backend" {
  mount = "kv"
  name  = "todogi_backend"
}
resource "helm_release" "todogi_backend" {
  name      = "todogi-backend"
  namespace = kubernetes_namespace.todogi_backend.metadata[0].name

  repository = "https://cantalay.github.io/helm-charts"
  chart      = "spring-boot-app"
  version    = "0.1.0"

  depends_on = [
    kubernetes_secret.todogi_backend
  ]

  values = [
    file("${path.module}/values-todogi-backend.yaml")
  ]

}

resource "kubernetes_secret" "todogi_backend" {
  metadata {
    name      = "todogi-backend-secrets"
    namespace = kubernetes_namespace.todogi_backend.metadata[0].name
  }

  data = {
    KEYCLOAK_ISSUER_URI = data.vault_kv_secret_v2.todogi_backend.data["KEYCLOAK_ISSUER_URI"]
    POSTGRE_DB_HOST     = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_HOST"]
    POSTGRE_DB_PORT     = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_PORT"]
    POSTGRE_DB_NAME     = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_NAME"]
    POSTGRE_DB_USERNAME = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_USERNAME"]
    POSTGRE_DB_PASSWORD = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_PASSWORD"]
    POSTGRE_DB_SCHEMA   = data.vault_kv_secret_v2.todogi_backend.data["POSTGRE_DB_SCHEMA"]
  }

  type = "Opaque"
}

resource "null_resource" "todogi_backend_cert" {
  depends_on = [
    helm_release.todogi_backend
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/todogi-backend-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/todogi-backend-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "todogi_backend_ingress" {
  depends_on = [
    null_resource.todogi_backend_cert
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/todogi-backend-ingress.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/todogi-backend-ingress.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
