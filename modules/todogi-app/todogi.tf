resource "kubernetes_namespace" "todogi_app" {
  metadata {
    name = "todogi-app"
  }
}

resource "helm_release" "todogi_app" {
  name      = "todogi"
  namespace = kubernetes_namespace.todogi_app.metadata[0].name

  repository = "https://cantalay.github.io/helm-charts"
  chart      = "expo-app"
  version    = "0.1.2"

  values = [
    file("${path.module}/values-todogi.yaml")
  ]

}

resource "null_resource" "todogi_cert" {
  depends_on = [
    helm_release.todogi_app
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/todogi-certificate.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/todogi-certificate.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
resource "null_resource" "todogi_ingress" {
  depends_on = [
    null_resource.todogi_cert
  ]

  triggers = {
    yaml_hash = filesha256("${path.module}/todogi-ingress.yaml")
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/todogi-ingress.yaml --kubeconfig=${path.root}/kubeconfig.yaml"
  }
}
