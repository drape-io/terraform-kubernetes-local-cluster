terraform {
  required_providers {
    kind = {
      # https://registry.terraform.io/providers/tehcyx/kind/latest/docs
      source  = "tehcyx/kind"
      version = "~> 0.2.1"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.22"
    }

    kubectl = {
      # Don't use gavinbunney, it is abandoned and has critical bugs. This
      # fork fixes it.   Critical issues:
      # https://github.com/gavinbunney/terraform-provider-kubectl/issues/270
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}
