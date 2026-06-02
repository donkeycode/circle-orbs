# donkeycode/rancher2

Deploy a project to Rancher 2 / managed Kubernetes (MKS) via Helm.
Companion of `donkeycode/rancher` (Rancher 1), which stays untouched.

## Job: deploy

```yaml
orbs:
  rancher2: donkeycode/rancher2@0.0.1
workflows:
  deploy:
    jobs:
      - rancher2/deploy:
          project_name: kinousassur
          env: ppd
          image_repository: <harbor>/<project>/<image>
          context: mks-<project>   # holds KUBE_SERVER / KUBE_TOKEN / KUBE_CA_B64
```

Auth: the `kube_login` command builds a kubeconfig from a namespace-scoped
ServiceAccount (`KUBE_SERVER`, `KUBE_TOKEN`, `KUBE_CA_B64`), provided by the
Terraform module `mks_deployer`.
