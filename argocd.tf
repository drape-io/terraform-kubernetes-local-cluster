# https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.10.5"
  namespace        = var.argocd_namespace
  create_namespace = true

  # Supply static credentials & API token values for development.
  # username: admin / password: admin123
  values = [<<YAML
crds:
  install: true
configs:
  cm:
    "accounts.kind_cluster": "apiKey,login"
  params:
    server.insecure: true
  secret:
    createSecret: true

    argocdServerAdminPassword: "$2a$10$KVscBZGucWmkXd5HtFwSHeVGKrKJM9EfRotC9N.V6tbwrftV3ab.a"
    argocdServerAdminPasswordMtime: "2023-02-22T21:33:46Z"

    extra:
      # API Token = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmdvY2QiLCJzdWIiOiJydWJyaWthOmFwaUtleSIsIm5iZiI6MTY5Mzg3OTU0NSwiaWF0IjoxNjkzODc5NTQ1LCJqdGkiOiJydWJyaWthLXRpbHQifQ.SIjQqXR2bT0wwOPRJEHSSTRi9Er-1qxGDOTyyQBSnO0
      "accounts.kind_cluster.tokens": "[{\"id\":\"kind_cluster\",\"iat\":1693879545}]"        

YAML

  ]

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]
}

module "argo_tls" {
  source    = "./modules/tls-cert"
  namespace = helm_release.argocd.namespace
  dns_names = [
    "argocd.${var.base_domain}"
  ]
  certs_path = var.certs_path

  depends_on = [
    kind_cluster.default,
    helm_release.argocd,
    helm_release.cert_manager,
  ]
}

resource "kubectl_manifest" "argocd_ingress" {
  yaml_body = <<YAML
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: argo
  namespace: ${helm_release.argocd.namespace}
spec:
  virtualhost:
    fqdn: argocd.${var.base_domain}
    tls:
      secretName: ${module.argo_tls.cert_secret}
  routes:
    - conditions:
      - prefix: /
      services:
        - name: argocd-server
          port: 80

YAML
  depends_on = [
    kind_cluster.default,
    helm_release.argocd,
    helm_release.contour,
    helm_release.cert_manager,
    module.argo_tls,
  ]
}
