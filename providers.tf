provider "helm" {
  debug = true
  kubernetes {
    config_path    = var.k8s_config_path
    config_context = "kind-${var.k8s_cluster_name}"
  }
}

provider "kubectl" {
  config_path      = var.k8s_config_path
  config_context   = "kind-${kind_cluster.default.name}"
  load_config_file = true
}

/* NOTE: Kubernetes provider requires the cluster to be setup during
planning which breaks compatibility.   Leaving this here to make sure
we don't try to use it later

Should rely on `kubectl` instead.
provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = "kind-${kind_cluster.default.name}"
}
*/
