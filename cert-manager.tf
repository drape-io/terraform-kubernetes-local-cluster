# https://cert-manager.io/docs/installation/helm/
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.21.2"
  namespace        = var.cert_manager_namespace
  create_namespace = true

  values = [<<YAML
crds:
  enabled: true
YAML
  ]

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]
}
