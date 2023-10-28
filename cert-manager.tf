data "kubectl_path_documents" "cert_manager_crd" {
  pattern = "${path.module}/kubernetes/cert_manager_crds/*.yml"
}

resource "kubectl_manifest" "cert_manager_crd" {
  for_each          = data.kubectl_path_documents.cert_manager_crd.manifests
  yaml_body         = each.value
  server_side_apply = true

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]
}

# https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/README.template.md
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.12.4"
  namespace        = var.cert_manager_namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "false"
  }

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]
}
