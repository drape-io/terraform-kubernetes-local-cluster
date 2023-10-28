terraform {
  required_providers {
    kubectl = {
      # Don't use gavinbunney, it is abandoned and has critical bugs. This
      # fork fixes it.   Critical issues:
      # https://github.com/gavinbunney/terraform-provider-kubectl/issues/270
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }
}
