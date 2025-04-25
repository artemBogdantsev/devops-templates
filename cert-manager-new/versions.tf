terraform {
  required_version = "~>1.4"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~>2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~>1.14"
    }
    null = {
      source  = "hashicorp/null"
      version = "~>3.2"
    }

    conjur = {
      source  = "cyberark/conjur"
      version = "0.6.2"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

provider "conjur" {
  appliance_url = "https://secrets-manager.telekom.de"
  account       = "dtag"
  ssl_cert_path = "./conjur-utils/conjur-cert.pem"
}