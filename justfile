help:
  @just --list

# Fetch the cert-manager CRDs
fetch-cert-manager-crds CERT_MANAGER_VERSION="v1.12.4":
    echo "Fetching cert-manager CRDS for {{CERT_MANAGER_VERSION}}"
    @CERT_MANAGER_URL=https://github.com/cert-manager/cert-manager/releases/download/{{CERT_MANAGER_VERSION}}/cert-manager.crds.yaml && \
        cd kubernetes/cert_manager_crds && \
        curl -Ls ${CERT_MANAGER_URL} | yq 'select(.kind == "CustomResourceDefinition")' -s '.spec.names.kind'
    @echo "Done"

# Fetch the Metal LB CRDs
fetch-metal-lb-crds METAL_LB_VERSION="v0.13.10":
    echo "Fetching Metal LB CRDS for {{METAL_LB_VERSION}}"
    @METAL_LB_URL=https://raw.githubusercontent.com/metallb/metallb/{{METAL_LB_VERSION}}/config/manifests/metallb-native.yaml && \
        cd kubernetes/metal_lb_crds && \
        curl -s ${METAL_LB_URL} | yq 'select(.kind == "CustomResourceDefinition")' -s '.spec.names.kind'
    @echo "Done"

# Fetch the contour CRDs
fetch-contour-crds CONTOUR_VERSION="v1.25.2":
    echo "Fetching contour CRDS for {{CONTOUR_VERSION}}"
    @CONTOUR_URL=https://raw.githubusercontent.com/projectcontour/contour/{{CONTOUR_VERSION}}/examples/render/contour.yaml && \
        cd kubernetes/contour_crds && \
        echo ${CONTOUR_URL} && \
        curl -s ${CONTOUR_URL} | yq 'select(.kind == "CustomResourceDefinition")' -s '.spec.names.kind'
    @echo "Done"

# Fetch the ArgoCD CRDs
fetch-argo-crds ARGO_VERSION="v2.8.2":
    echo "Fetching argo CRDS for {{ARGO_VERSION}}"
    @ARGO_URL=https://raw.githubusercontent.com/argoproj/argo-cd/{{ARGO_VERSION}}/manifests/install.yaml && \
        cd kubernetes/argocd_crds && \
        curl -s ${ARGO_URL} | yq 'select(.kind == "CustomResourceDefinition")' -s '.spec.names.kind'
    @echo "Done"

# Get the CRDS we use in our cluster
fetch-crds: fetch-contour-crds fetch-argo-crds fetch-metal-lb-crds
    @echo "All CRDs are fetched!"