terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }

    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}

provider "kubernetes" {
  config_path = "${path.module}/kubeconfig.yaml"
}

provider "helm" {
  kubernetes = {
    config_path = "${path.module}/kubeconfig.yaml"
  }
}
