#!/bin/bash
set -euo pipefail

echo "🔹 Terraform import starting..."
echo "--------------------------------"

terraform init

# ------------------------------------------------------------------------------
# NAMESPACES
# ------------------------------------------------------------------------------
echo "📦 Importing namespaces..."

terraform import module.traefik.kubernetes_namespace.traefik traefik
terraform import module.cert_manager.kubernetes_namespace.cert_manager cert-manager
terraform import module.keycloak.kubernetes_namespace.keycloak keycloak
terraform import module.loki.kubernetes_namespace.loki loki
terraform import module.promtail.kubernetes_namespace.promtail promtail
terraform import module.tempo.kubernetes_namespace.tempo tempo
terraform import module.grafana.kubernetes_namespace.grafana grafana
terraform import module.postgresql.kubernetes_namespace.database database

# ------------------------------------------------------------------------------
# HELM RELEASES
# ------------------------------------------------------------------------------
echo "⛵ Importing helm releases..."

terraform import module.traefik.helm_release.traefik traefik
terraform import module.cert_manager.helm_release.cert_manager cert-manager
terraform import module.keycloak.helm_release.keycloak keycloak
terraform import module.loki.helm_release.loki loki
terraform import module.promtail.helm_release.promtail promtail
terraform import module.tempo.helm_release.tempo tempo
terraform import module.grafana.helm_release.grafana grafana
terraform import module.postgresql.helm_release.postgresql postgresql

# ------------------------------------------------------------------------------
# SECRETS (EXAMPLE)
# ------------------------------------------------------------------------------
echo "🔐 Importing secrets..."

terraform import \
  module.keycloak.kubernetes_secret.keycloak_secrets \
  keycloak/keycloak-secrets

terraform import \
  module.postgresql.kubernetes_secret.postgres_secrets \
  database/postgresql-secrets

echo "--------------------------------"
echo "✅ Terraform import completed successfully"
