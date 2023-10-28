data "kubectl_path_documents" "contour_crd" {
  pattern = "${path.module}/kubernetes/contour_crds/*.yml"
}

resource "kubectl_manifest" "contour_crd" {
  for_each          = data.kubectl_path_documents.contour_crd.manifests
  yaml_body         = each.value
  server_side_apply = true

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]
}

// https://bitnami.com/stack/contour/helm
// https://github.com/bitnami/charts/tree/main/bitnami/contour
resource "helm_release" "contour" {
  name             = "contour"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "contour"
  version          = "12.6.0"
  namespace        = var.contour_namespace
  create_namespace = true

  set {
    name  = "contour.image.pullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "contour.manageCRDs"
    value = "false"
  }

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    helm_release.metal_lb,
    kubectl_manifest.contour_crd,
    kubectl_manifest.metallb_ip_address_pool,
  ]
}
