# Official fork of the (discontinued) Bitnami chart:
# https://github.com/projectcontour/helm-charts/tree/main/charts/contour
resource "helm_release" "contour" {
  name             = "contour"
  repository       = "https://projectcontour.github.io/helm-charts/"
  chart            = "contour"
  version          = "0.8.0"
  namespace        = var.contour_namespace
  create_namespace = true

  values = [<<YAML
contour:
  manageCRDs: true
YAML
  ]

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    helm_release.metal_lb,
    kubectl_manifest.metallb_ip_address_pool,
  ]
}
