resource "kubernetes_namespace" "auth_gateway" {
  metadata {
    name = "gateway"
  }
}
data "vault_kv_secret_v2" "auth_gateway" {
  mount = "kv"
  name  = "todogi"
}
resource "helm_release" "auth_gateway" {
  name       = "auth-gateway"
  namespace  = kubernetes_namespace.auth_gateway.metadata[0].name

  repository = "https://cantalay.github.io/helm-charts"
  chart      = "spring-boot-app"
  version    = "0.1.0"

  depends_on = [
    kubernetes_secret.auth_gateway
  ]

  values = [
    file("${path.module}/values-gateway.yaml")
  ]

}

resource "kubernetes_secret" "auth_gateway" {
  metadata {
    name      = "auth-gateway-secrets"
    namespace = kubernetes_namespace.auth_gateway.metadata[0].name
  }

  data = {
    KEYCLOAK_ISSUER_URI          = data.vault_kv_secret_v2.auth_gateway.data["KEYCLOAK_ISSUER_URI"]
    KEYCLOAK_BASE_URL            = data.vault_kv_secret_v2.auth_gateway.data["KEYCLOAK_BASE_URL"]
    KEYCLOAK_REALM               = data.vault_kv_secret_v2.auth_gateway.data["KEYCLOAK_REALM"]
    KEYCLOAK_ADMIN_CLIENT_ID     = data.vault_kv_secret_v2.auth_gateway.data["KEYCLOAK_ADMIN_CLIENT_ID"]
    KEYCLOAK_ADMIN_CLIENT_SECRET = data.vault_kv_secret_v2.auth_gateway.data["KEYCLOAK_ADMIN_CLIENT_SECRET"]
  }

  type = "Opaque"
}

resource "null_resource" "auth_gateway_cert" {
  depends_on = [
    helm_release.auth_gateway
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/gateway-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/gateway-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "auth_gateway_ingress" {
  depends_on = [
    null_resource.auth_gateway_cert
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/gateway-ingress.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/gateway-ingress.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}