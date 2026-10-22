# Configure from the kind_cluster attributes rather than the kubeconfig file so
# that planning works before the cluster (and its kubeconfig) exists.
provider "helm" {
  kubernetes = {
    host                   = kind_cluster.default.endpoint
    client_certificate     = kind_cluster.default.client_certificate
    client_key             = kind_cluster.default.client_key
    cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  }
}

provider "kubectl" {
  host                   = kind_cluster.default.endpoint
  client_certificate     = kind_cluster.default.client_certificate
  client_key             = kind_cluster.default.client_key
  cluster_ca_certificate = kind_cluster.default.cluster_ca_certificate
  load_config_file       = false
  # The attributes above are unknown until kind_cluster is created.
  lazy_load = true
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
