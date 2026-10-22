terraform {
  required_version = ">= 1.6"

  required_providers {
    kind = {
      # https://registry.terraform.io/providers/tehcyx/kind/latest/docs
      source  = "tehcyx/kind"
      version = "~> 0.13"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6"
    }

    kubectl = {
      # Don't use gavinbunney, it is abandoned and has critical bugs. This
      # fork fixes it.   Critical issues:
      # https://github.com/gavinbunney/terraform-provider-kubectl/issues/270
      source  = "alekc/kubectl"
      version = "~> 2.4"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3"
    }
  }
}
