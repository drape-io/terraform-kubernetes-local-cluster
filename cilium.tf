locals {
  cilium_cert_secret = "cilium-https-cert"
}

resource "helm_release" "cilium" {
  count            = var.use_cilium ? 1 : 0
  name             = "cilium"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.14.1"
  namespace        = var.cilium_namespace
  create_namespace = true

  set {
    name  = "image.pullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  set {
    name  = "hubble.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }
  # Make sure `kind` has written the `kubeconfig` before we move forward
  # with installing helm.
  depends_on = [kind_cluster.default]
}

module "cilium_tls" {
  count     = var.use_cilium ? 1 : 0
  source    = "./modules/tls-cert"
  namespace = helm_release.cilium[0].namespace
  dns_names = [
    "hubble.${var.base_domain}"
  ]
  certs_path = var.certs_path

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    helm_release.cert_manager,
  ]
}

resource "kubectl_manifest" "hubble_grpc_service" {
  count     = var.use_cilium ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: hubble-ui-grpc
  namespace: ${helm_release.cilium[0].namespace}
spec:
  ports:
  - name: grpc
    port: 80
    protocol: TCP
    targetPort: 8090
  selector:
    k8s-app: hubble-ui
  type: ClusterIP
YAML
  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    helm_release.contour,
    helm_release.cert_manager,
  ]
}


resource "kubectl_manifest" "hubble_ingress" {
  count     = var.use_cilium ? 1 : 0
  yaml_body = <<YAML
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: hubble-ui
  namespace: ${helm_release.cilium[0].namespace}
spec:
  virtualhost:
    fqdn: hubble.${var.base_domain}
    tls:
      secretName: ${module.cilium_tls[0].cert_secret}
  routes:
    - conditions:
      - prefix: /api
      enableWebsockets: true
      services:
        - name: hubble-ui-grpc
          port: 80
          protocol: h2c
      timeoutPolicy:
        response: 1h

    - conditions:
      - prefix: /
      enableWebsockets: true
      services:
        - name: hubble-ui
          port: 80
YAML
  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    helm_release.contour,
    helm_release.cert_manager,
    kubectl_manifest.hubble_grpc_service,
    module.cilium_tls,
  ]
}