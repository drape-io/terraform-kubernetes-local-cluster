locals {
  metal_lb_namespace = "metallb"
}

data "kubectl_path_documents" "metallb_crd" {
  pattern = "${path.module}/kubernetes/metal_lb_crds/*.yml"
}

data "docker_network" "kind_network" {
  name = "kind"

  depends_on = [
    kind_cluster.default,
  ]
}

output "subnet" {
  value = local.docker_subnet
}

resource "kubectl_manifest" "metallb_crd" {
  for_each = data.kubectl_path_documents.metallb_crd.manifests

  yaml_body         = each.value
  server_side_apply = true

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
  ]

  ignore_fields = [
    "spec.conversion.webhook.clientConfig.caBundle",
  ]
}

// https://github.com/metallb/metallb/tree/main/charts/metallb
resource "helm_release" "metal_lb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = "0.13.10"
  namespace        = local.metal_lb_namespace
  create_namespace = true

  set {
    name  = "controller.image.pullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "speaker.image.pullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "crds.enabled"
    value = "false"
  }

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
    kubectl_manifest.contour_crd
  ]
}

locals {
  docker_ipv4_networks = [
    for cidr in data.docker_network.kind_network.ipam_config : cidr
    if can(cidrnetmask(cidr.subnet))
  ]
  docker_subnet = local.docker_ipv4_networks[0].subnet
}

resource "kubectl_manifest" "metallb_ip_address_pool" {
  yaml_body = <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: kind
  namespace: ${local.metal_lb_namespace}
spec:
  addresses:
  - ${cidrhost(local.docker_subnet, 200)}-${cidrhost(local.docker_subnet, 250)}
EOF

  depends_on = [helm_release.metal_lb]
}

resource "kubectl_manifest" "metallb_l2_advertisement" {
  yaml_body = <<EOF
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: ${local.metal_lb_namespace}
EOF

  depends_on = [helm_release.metal_lb]
  ignore_fields = [
    "metadata.managedFields",
    "metadata.generation",
  ]
}
