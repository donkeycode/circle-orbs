# Design — Skill open source `donkeycode-orbs`

**Date** : 2026-06-04
**Auteur** : Cédric Lombardot (via Jarvis)
**Statut** : validé en brainstorming, en attente de relecture utilisateur

## 1. Objectif

Créer un skill open source — sur le même modèle que `cucumber-sentences` — qui
explique comment **coder un projet avec CircleCI en utilisant les orbs personnels
`donkeycode/*`**. Le skill sert de référence pour un agent (ou un humain) qui doit
écrire / éditer un `.circleci/config.yml` câblant le flux build → push → deploy.

## 2. Décisions de cadrage (validées en brainstorming)

| Décision | Choix retenu |
|----------|--------------|
| Emplacement | Nouveau repo Git autonome `~/circleci-orbs-skill/`, publiable sur `donkeycode/circleci-orbs-skill` |
| Périmètre | Les **8 orbs** au catalogue + un walkthrough détaillé du flux deploy (exemple `kinousassur`) |
| Format | **Skill simple** (SKILL.md + README + references/ + templates/), pas de plugin.json |
| Anonymisation | **Hybride** : templates 100% anonymisés (placeholders) + un bloc "real-world example" `kinousassur` complet dans `references/` |

## 3. Nom & déclencheur du skill

- **name** : `donkeycode-orbs`
- **description** (frontmatter) :
  > Use when writing or editing a `.circleci/config.yml` in a project that deploys
  > via the donkeycode CircleCI orbs (symfony, docker, rancher2, angular, wordpress,
  > trivy, utils, rancher). Triggers when wiring a build→push→deploy pipeline, adding
  > a job from one of these orbs, debugging a context/env-var/token issue (Harbor,
  > MKS/Kubernetes), or scaffolding a Helm deploy on Rancher 2.

## 4. Arborescence cible

```
circleci-orbs-skill/
├── SKILL.md                          # mental model + decision tree + templates rapides
├── README.md                         # install / triggers / what's inside / compat / license
├── LICENSE                           # MIT
├── references/
│   ├── orbs-catalogue.md             # les 8 orbs : params/jobs/commands exacts, tableaux
│   ├── deploy-pipeline.md            # deep dive build→push→deploy (Harbor + Rancher2/MKS/Helm)
│   └── contexts-and-secrets.md       # contrat CircleCI : contextes mks/harbor, KUBE_TOKEN_<ENV>, pièges
└── templates/
    ├── config.symfony-rancher2.yml   # pipeline complet type kinousassur (ppd+prod, approvals) — ANONYMISÉ
    ├── config.angular-rancher2.yml   # variante front Angular — ANONYMISÉ
    ├── chart-values.yaml             # squelette values Helm + values.<env>.yaml
    └── Dockerfile-php-fpm            # Dockerfile d'exemple
```

## 5. Contenu de SKILL.md

### 5.1 Mental model central — « 3 hops »

> **Un pipeline donkeycode = 3 hops : `prepare` → `build` + `push` → `deploy`.**
> - **prepare** (`symfony/prepare`, `angular/prepare`, `wordpress/prepare`) : installe
>   les deps, build les assets (Encore/npm), met en cache → persiste le workspace.
> - **build** (`symfony/build`, `angular/build`) + **`docker/push_images`** : construit
>   l'image Docker et la pousse vers le registry (Harbor via `use_docker_login`, ou AWS ECR).
> - **deploy** (`rancher2/deploy`) : `helm upgrade --install` sur le namespace MKS,
>   rollout forcé via `deployRevision=$CIRCLE_SHA1`.

### 5.2 Decision tree (style cucumber)

Algorithme de diagnostic numéroté, ex. :
1. Job *undefined* ? → l'orb est-il déclaré dans `orbs:` ? la version existe-t-elle ?
2. `KUBE_SERVER`/`KUBE_CA_B64` manquant ? → attacher le contexte `mks`.
3. Token absent ? → définir `KUBE_TOKEN_<ENV>` (PREPROD/PROD) dans les **variables du
   projet** CircleCI, pas dans le contexte. Fallback legacy `KUBE_TOKEN`.
4. Rollout qui ne part pas alors que le tag n'a pas changé ? → c'est `deployRevision` qui
   force le rollout ; vérifier que le chart le consomme sur le pod template.
5. `helm` qui timeout au discovery (`client rate limiter Wait ... context deadline
   exceeded`) ? → cluster Rancher = beaucoup de CRDs → `HELM_BURST_LIMIT`/`HELM_QPS`.

### 5.3 Templates rapides (copy/adapt)

Snippets courts : déclaration `orbs:`, un job `rancher2/deploy` minimal, ancre YAML
`branch_preprod`/`branch_prod`, bloc `hold` (approval).

### 5.4 Hidden contracts (les pièges réels)

- `rancher2/deploy` : `namespace` est **requis** (CircleCI interdit un default qui
  référence un autre paramètre → pas de dérivation auto depuis `project_name`).
- Contexte `mks` (cluster-wide : `KUBE_SERVER` + `KUBE_CA_B64`) ≠ token, qui est une var
  **projet** par env (`KUBE_TOKEN_PREPROD` / `KUBE_TOKEN_PROD`).
- `image_tag` vide → défaut `<env>` (preprod/prod), comportement legacy ; rollout forcé
  quand même.
- `release_name` vide → défaut = `namespace`.
- `values.<env>.yaml` appliqué seulement s'il existe (override optionnel).
- `hold_prod` placé **avant** le build (split précoce) pour éviter un push Harbor inutile.
- Dépendances entre orbs (ex. `rancher2 → utils@0.0.2`, `symfony → docker/node/utils`).

### 5.5 Verification checklist

Checklist avant de déclarer un `config.yml` « terminé » (orbs déclarés + versions,
contextes attachés, vars projet présentes par env, `requires:` cohérents, filtres de
branche, chart présent).

## 6. Contenu des références

- **orbs-catalogue.md** : un tableau par orb (angular, docker, rancher, rancher2,
  symfony, trivy, utils, wordpress) → executors, jobs, commands, paramètres (nom, type,
  default, requis), dépendances, version courante. Données issues de l'exploration du
  repo `circle-orbs`.
- **deploy-pipeline.md** : deep dive du flux complet build→push→deploy avec le bloc
  **« Real-world example : kinousassur »** (config réelle complète, registry OVH réel,
  namespaces réels, chart Helm) — partie assumée non anonymisée de l'hybride.
- **contexts-and-secrets.md** : contrat CircleCI exhaustif — tableau variable / scope /
  emplacement / source Terraform ; résolution du token (`token_var` → `KUBE_TOKEN_<ENV>`
  → `KUBE_TOKEN`) ; contexte `harbor` (`DOCKER_REGISTRY`/`DOCKER_LOGIN`/`DOCKER_PASSWORD`).

## 7. Templates (anonymisés)

- `config.symfony-rancher2.yml` : reprend la structure `kinousassur` (develop→preprod,
  main→prod, approvals, Harbor + MKS) avec placeholders `<project>`,
  `<your-harbor-registry>`, `<namespace>`.
- `config.angular-rancher2.yml` : variante front (angular/prepare + angular/build + deploy).
- `chart-values.yaml` : squelette `values.yaml` + note sur `values.<env>.yaml`.
- `Dockerfile-php-fpm` : Dockerfile d'exemple basé sur l'image `donkeycode/php-*-symfony`.

## 8. Ton & conventions

Pragmatique / empirique (comme cucumber-sentences) : tableaux, params exacts, pièges
vécus, checklists. Pas de prose théorique. Frontmatter YAML minimal (`name`,
`description`). Références chargées à la demande, pas de duplication prose.

## 9. Hors périmètre (YAGNI)

- Pas de `plugin.json` / `marketplace.json` (format skill simple).
- Pas de documentation de la mécanique de **publication** des orbs (Makefile, orb-tools) —
  le skill cible la **consommation** des orbs dans un projet, pas leur édition.
- Pas de génération de chart Helm complet (seul un squelette de values).
