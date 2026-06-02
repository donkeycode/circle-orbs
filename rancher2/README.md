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
          # KUBE_TOKEN comes from the PROJECT's CircleCI env vars (scoped SA token),
          # not a dedicated mks-<project> context.
```

## Image tag & rollout (legacy behaviour)

Deploys the **env-named tag** (`preprod`/`prod`), exactly like the Rancher 1 flow. Because
that tag does not change between two releases, the orb forces a rollout via
`--set deployRevision=$CIRCLE_SHA1` (the chart puts it on the pod template, so the spec
changes each release → rollout), with `imagePullPolicy: Always`. This is the K8s equivalent
of `rancher up --force-upgrade --pull`.

## Auth — CircleCI context contract

The `kube_login` command builds a kubeconfig from these env vars (it FAILS with a clear
message if any is missing). Cluster-wide values live in a shared context; the scoped token
lives at the project level:

| Variable | Scope | Where | Source (Terraform) |
|----------|-------|-------|--------------------|
| `KUBE_SERVER` | cluster-wide (generic) | global context, e.g. `mks` | `mks_ci_kube_server` |
| `KUBE_CA_B64` | cluster-wide (generic) | global context, e.g. `mks` | `mks_ci_kube_ca_b64` |
| `KUBE_TOKEN` | **per project** (scoped SA) | the **project's CircleCI env vars** | `module.<project>_<env>_deployer.token` |

The per-project token comes from a ServiceAccount scoped to the project namespace
(module `mks_deployer`) → the CI can only act on that one namespace (blast radius minimal).
Attach the `mks` context to the job (`context: mks`); `KUBE_TOKEN` is injected from the
project's environment variables — no dedicated `mks-<project>` context needed.
