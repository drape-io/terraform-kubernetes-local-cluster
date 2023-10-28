module "local-cluster" {
  source           = "../"
  certs_path       = "./.certs"
  k8s_config_path  = "./kubeconfig-cluster1"
  k8s_cluster_name = "example-kind-cluster"
  base_domain      = "local-cluster.dev"
  cidr_start       = 200
  cidr_end         = 205
}

module "best-cluster" {
  source           = "../"
  certs_path       = "./.certs"
  k8s_config_path  = "./kubeconfig-cluster2"
  k8s_cluster_name = "example-kind-cluster2"
  base_domain      = "best-cluster.dev"
  cidr_start       = 206
  cidr_end         = 210
}
