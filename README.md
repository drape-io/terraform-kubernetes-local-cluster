# Manage a local kind cluster
This module will spin you up a local kind cluster that is provisioned closer to
a "real" cluster.  It includes an ingress controller, loadbalancer,
certificates, and an image registry.

You only need Docker (or a Docker-compatible runtime such as Colima or
OrbStack), Terraform, and [mkcert](https://github.com/FiloSottile/mkcert). The `kind` provider embeds kind, so the `kind` CLI is
optional; it's handy for `kind get clusters` / `kind delete cluster`.

Versions of the dev tooling are pinned in `mise.toml`; run `mise install` to
get them.


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
    source  = "drape-io/local-cluster/kubernetes"
    version = "0.1.0"
    certs_path = "./.certs"
    k8s_config_path = "./kubeconfig"
    k8s_cluster_name = "example-kind-cluster"
    base_domain = "local-cluster.dev"
}
```

`base_domain` will be a domain you will setup in `/etc/hosts` that will point
to the `LoadBalancer` in your cluster.

`k8s_config_path` is where the module writes the new cluster's kubeconfig.
Give it a dedicated file such as `./kubeconfig`; don't point it at a
kubeconfig you use for other clusters.

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

# Upgrading from 0.0.x
This release is not an in-place upgrade. It changes the default Kubernetes
version, which recreates the kind cluster, and the charts now own their CRDs
instead of the module applying them separately. The module now requires
Terraform >= 1.6 and newer providers (`hashicorp/helm ~> 3.3`,
`kreuzwerker/docker ~> 4.6`, `tehcyx/kind ~> 0.13`, `alekc/kubectl ~> 2.4`),
so update any matching pins in your root module.

Run `terraform destroy` with the old module version, bump the version, then
run `terraform apply`.

# Multiple Clusters
If you want to run multiple clusters with this module you'll want the clusters
to have different CIDR ranges.   To do this you can use the variables
`cidr_start` and `cidr_end` and make sure they don't conflict.  You will also
want to make sure you generate different `kubeconfig` paths for each.

A configuration could look something like this:

```
module "local-cluster" {
  source  = "drape-io/local-cluster/kubernetes"
  version = "0.1.0"

  certs_path       = "./.certs"
  k8s_config_path  = "./kubeconfig-cluster1"
  k8s_cluster_name = "example-kind-cluster"
  base_domain      = "local-cluster.dev"
  cidr_start       = 200
  cidr_end         = 205
}

module "best-cluster" {
  source  = "drape-io/local-cluster/kubernetes"
  version = "0.1.0"
  certs_path       = "./.certs"
  k8s_config_path  = "./kubeconfig-cluster2"
  k8s_cluster_name = "example-kind-cluster2"
  base_domain      = "best-cluster.dev"
  cidr_start       = 206
  cidr_end         = 210
}
```

# Namespaces
If you want to provision some additional namespaces to make sure they are
ready to be used by helm/kustomize/etc you can pass `namespaces` variable as a
list.

```hcl
namespaces = [
  "foo",
  "bar",
]
```

# TLS certs
If you want additonal certificates generated you can provide a map of namespaces
and a list of domains you want generated for them with `additional_certs`
variable:

```hcl
additional_certs = {
  "foo": [
    "foo.dev"
  ],
  "bar": [
    "bar.dev"
  ]
}
```

# Troubleshooting

## `failed to join node with kubeadm`
On Linux hosts this is almost always the inotify limits being too low for a
multi-node cluster ([kind known issue](https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files)).
Raise them and re-apply:

```bash
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl fs.inotify.max_user_instances=512
```

To keep the change across reboots, add the same settings to
`/etc/sysctl.d/99-kind.conf`. You can also create fewer nodes with
`worker_count = 1` (or `0`).

## `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`
The docker provider doesn't read your docker CLI context. If you use Colima,
OrbStack, etc., export `DOCKER_HOST` first, for example:

```bash
export DOCKER_HOST=$(docker context inspect --format '{{.Endpoints.docker.Host}}')
```

## etcd crashes or pods are evicted
Check the free disk space in your Docker VM. The node images plus everything
the cluster pulls need roughly 10 GB.
