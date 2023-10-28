module "httpbin_tls" {
  count     = var.enable_httpbin ? 1 : 0
  source    = "./modules/tls-cert"
  namespace = "default"
  dns_names = [
    "httpbin.${var.base_domain}"
  ]
  certs_path = var.certs_path

  depends_on = [
    kind_cluster.default,
    helm_release.cert_manager,
  ]
}

resource "kubectl_manifest" "httpbin_service" {
  count     = var.enable_httpbin ? 1 : 0
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: default
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 8080
  selector:
    app: httpbin
YAML
  depends_on = [
    kind_cluster.default,
    helm_release.cert_manager,
    kubectl_manifest.argo_crd,
    module.httpbin_tls,
  ]
}

resource "kubectl_manifest" "httpbin_deployment" {
  count     = var.enable_httpbin ? 1 : 0
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
    spec:
      containers:
      - image: docker.io/mccutchen/go-httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 8080
YAML
  depends_on = [
    kind_cluster.default,
    helm_release.cert_manager,
    kubectl_manifest.httpbin_service,
    module.httpbin_tls,
  ]
}

resource "kubectl_manifest" "httpbin_ingress" {
  count     = var.enable_httpbin ? 1 : 0
  yaml_body = <<YAML
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: httpbin
  namespace: default
spec:
  virtualhost:
    fqdn: httpbin.${var.base_domain}
    tls:
      secretName: ${module.httpbin_tls[0].cert_secret}
  routes:
    - conditions:
      - prefix: /
      services:
        - name: httpbin
          port: 8000
YAML
  depends_on = [
    kind_cluster.default,
    helm_release.cert_manager,
    kubectl_manifest.httpbin_deployment,
    module.httpbin_tls,
  ]
}
