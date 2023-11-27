module "additional_tls" {
  for_each   = var.additional_certs
  source     = "./modules/tls-cert"
  namespace  = each.key
  dns_names  = each.value
  certs_path = var.certs_path

  depends_on = [
    kind_cluster.default,
    helm_release.cert_manager,
  ]
}