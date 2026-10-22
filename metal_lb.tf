locals {
  metal_lb_namespace = "metallb"
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

// https://github.com/metallb/metallb/tree/main/charts/metallb
resource "helm_release" "metal_lb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  version          = "0.16.1"
  namespace        = local.metal_lb_namespace
  create_namespace = true

  values = [<<YAML
crds:
  enabled: true
# We only use L2 mode. frr-k8s (BGP) adds a pod per node and readily exhausts
# inotify limits on small Docker VMs.
frrk8s:
  enabled: false
YAML
  ]

  depends_on = [
    kind_cluster.default,
    helm_release.cilium,
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
  - ${cidrhost(local.docker_subnet, var.cidr_start)}-${cidrhost(local.docker_subnet, var.cidr_end)}
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
