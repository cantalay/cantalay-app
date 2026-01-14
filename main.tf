locals {
  k3s_install = <<-EOF
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable traefik" sh -
  EOF
}

resource "null_resource" "install_k3s" {
  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing K3s...'",
      local.k3s_install
    ]
  }
}

resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.install_k3s]

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/k3s",
      "cp /etc/rancher/k3s/k3s.yaml /tmp/k3s/config",
      "sed -i 's/127.0.0.1/${var.server_ip}/g' /tmp/k3s/config"
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no ${var.ssh_user}@${var.server_ip}:/tmp/k3s/config kubeconfig.yaml"
  }
}

output "kubeconfig_file" {
  value = "${path.module}/kubeconfig.yaml"
}

provider "vault" {
  address = "https://vault.cantalay.com"
  token   = ""
}

# module "n8n" {
#   source = "./modules/n8n"
#
#   depends_on = [
#     null_resource.get_kubeconfig,
# #     module.redis, need redis look cantalay base
#   ]
# }
terraform {
  backend "kubernetes" {
    namespace        = "terraform-states" # State'in saklanacağı yer
    secret_suffix    = "app-state"      # Secret adının sonuna eklenir
    config_path   = "/home/cant/.kube/config"
  }
}
module "gateway" {
  source = "./modules/auth-gateway"
  depends_on = [
    module.keycloak
  ]
}
module "todogi_app" {
  source = "./modules/todogi-app"
    depends_on = [
        module.gateway
    ]
}
module "todogi_backend" {
  source = "./modules/todogi-backend"
  depends_on = [
    module.keycloak
  ]
}

module "keycloak" {
  source = "./modules/keycloak"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [
    null_resource.get_kubeconfig,
  ]
}