# donkeycode/rancher2

Deploy a project to Rancher 2 / managed Kubernetes (MKS) via Helm.
Companion of `donkeycode/rancher` (Rancher 1), which stays untouched.

## Job: deploy

```yaml
orbs:
  rancher2: donkeycode/rancher2@0.0.2
workflows:
  deploy:
    jobs:
      - rancher2/deploy:
          project_name: kinousassur
          env: preprod                       # preprod | prod (legacy syntax)
          namespace: kinousassur-ppd         # explicit (the project namespace)
          image_repository: <harbor>/<project>/<image>
          # image_tag defaults to <env> (preprod/prod) ; rollout is forced anyway
          context:
            - mks                            # global: KUBE_SERVER + KUBE_CA_B64
            - mks-kinousassur                # per-project: KUBE_TOKEN (scoped SA)
```

## Image tag & rollout (legacy behaviour)

Deploys the **env-named tag** (`preprod`/`prod`), exactly like the Rancher 1 flow. Because
that tag does not change between two releases, the orb forces a rollout via
`--set deployRevision=$CIRCLE_SHA1` (the chart puts it on the pod template, so the spec
changes each release → rollout), with `imagePullPolicy: Always`. This is the K8s equivalent
of `rancher up --force-upgrade --pull`.

## Auth — CircleCI context contract

The `kube_login` command builds a kubeconfig from these env vars (it FAILS with a clear
message if any is missing). Split across two contexts so the cluster-wide values are not
duplicated per project, while the token stays scoped per project:

| Variable | Scope | Context (suggested) | Source (Terraform) |
|----------|-------|---------------------|--------------------|
| `KUBE_SERVER` | cluster-wide (generic) | global, e.g. `mks` | MKS kubeconfig (`...clusters[0].cluster.server`) |
| `KUBE_CA_B64` | cluster-wide (generic) | global, e.g. `mks` | MKS cluster CA, base64 |
| `KUBE_TOKEN` | **per project** (scoped SA) | per-project, e.g. `mks-<project>` | `module.<project>_<env>_deployer.token` |

The per-project token comes from a ServiceAccount scoped to the project namespace
(module `mks_deployer`) → the CI can only act on that one namespace (blast radius minimal).
Attach BOTH contexts to the job: `context: [mks, mks-<project>]`.
