resource "kubectl_manifest" "root_cert" {
  yaml_body = <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${var.root_cert_name}
  namespace: ${var.namespace}
type: kubernetes.io/tls
data:
  tls.key: "${filebase64("${var.certs_path}/rootCA-key.pem")}"
  tls.crt: "${filebase64("${var.certs_path}/rootCA.pem")}"
EOF
}

resource "kubectl_manifest" "cert_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: ${var.namespace}
spec:
  ca:
    secretName: ${var.root_cert_name}

YAML

  depends_on = [
    kubectl_manifest.root_cert
  ]
}

resource "kubectl_manifest" "certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-certificate
  namespace: ${var.namespace}
spec:
  secretName: ${local.cert_secret}
  dnsNames: ${jsonencode(var.dns_names)}
  privateKey:
    rotationPolicy: "Always"
  issuerRef:
    name: ca-issuer
    kind: "Issuer"

YAML
  depends_on = [
    kubectl_manifest.cert_issuer,
  ]
}
