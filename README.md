# Manage a local kind cluster
This module will spin you up a local kind cluster that is provisioned closer to
a "real" cluster.  It includes an ingress controller, loadbalancer,
certificates, and an image registry.

Make sure you have [kind](https://kind.sigs.k8s.io/) installed.


# Getting Started
First, you need to setup a local certificate for signing the certs the cluster
will create.  To do this we use [mkcert](https://github.com/FiloSottile/mkcert).

It doesn't matter where you create the certificate because you will pass in the
path as a variable later.   This will create it in your current directory under
a folder `.certs`:

```bash
CA_CERTS_FOLDER=$(pwd)/.certs && \
    echo ${CA_CERTS_FOLDER} && \
    mkdir -p ${CA_CERTS_FOLDER} && \
    CAROOT=${CA_CERTS_FOLDER} mkcert -install
```

Then create a `main.tf` file to create your first cluster:

```hcl
module "local-cluster" {
    source = "../"
    certs_path = "./.certs"
    k8s_config_path = "./kubeconfig"
    k8s_cluster_name = "example-kind-cluster"
    base_domain = "local-cluster.dev"
}
```

`base_domain` will be a domain you will setup in `/etc/hosts` that will point
to the `LoadBalancer` in your cluster.

Now run it:

```bash
tf init && tf apply
```

After it is applied you will now have a `LoadBalancer` with an external IP that
you can use:

```
> kubectl get svc contour-envoy -n contour 
NAME            TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                      AGE
contour-envoy   LoadBalancer   10.96.143.82   192.168.228.200   80:30890/TCP,443:32048/TCP   16m
```

So now you can setup your `/etc/hosts` to point your `base_domain` to that
external IP, for example if your base-domain is `local-cluster.dev` then you
can add this line:

```
192.168.228.200 local-cluster.dev trow.local-cluster.dev argocd.local-cluster.dev httpbin.local-cluster.dev
```

Now you will have access to:

Local Docker Registry:
https://trow.local-cluster.dev

ArgoCD:
https://argocd.local-cluster.dev

HTTPBin:
https://httpbin.local-cluster.dev