module "local-cluster" {
  source           = "../"
  certs_path       = "./.certs"
  k8s_config_path  = "./kubeconfig"
  k8s_cluster_name = "example-kind-cluster"
  base_domain      = "local-cluster.dev"
}
