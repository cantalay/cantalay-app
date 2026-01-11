resource "kubernetes_namespace" "keycloak" {
  metadata {
    name = "keycloak"
  }
}

data "vault_kv_secret_v2" "keycloak_admin" {
  mount = "kv"
  name  = "keycloak/admin"
}

# Create secret FIRST
resource "kubernetes_secret" "keycloak_secrets" {
  metadata {
    name      = "keycloak-secrets"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
  }

  data = {
    KEYCLOAK_ADMIN_PASSWORD = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_ADMIN_PASS"]
    KEYCLOAK_ADMIN_USER = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_ADMIN_USER"]
    KC_DB_PASSWORD          = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_DB_PASS"]
    KC_DB_NAME          = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_DB_TYPE"]
    KC_DB_URL          = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_DB_URL"]
    KC_DB_USERNAME          = data.vault_kv_secret_v2.keycloak_admin.data["KEYCLOAK_DB_USERNAME"]
  }
}


resource "helm_release" "keycloak" {
  name       = "keycloak"
  namespace  = kubernetes_namespace.keycloak.metadata[0].name
  repository = "https://codecentric.github.io/helm-charts"
  chart      = "keycloakx"
  version    = "7.1.5"

  values = [
    file("${path.module}/values-keycloak.yaml")
  ]
  depends_on = [
    kubernetes_secret.keycloak_secrets
  ]
}

resource "null_resource" "keycloak_dashboard_cert" {
  depends_on = [helm_release.keycloak]

  triggers = {
    yaml_hash = filesha256("${path.module}/dashboard-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/dashboard-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "keycloak_ingress" {
  triggers = {
    yaml_hash = filesha256("${path.module}/keycloak-ingress.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/keycloak-ingress.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }

  depends_on = [
    null_resource.keycloak_dashboard_cert
  ]
}