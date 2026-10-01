# Infra Platform

Terraform modules for a baseline AWS platform (VPC, EKS, RDS), plus the GitOps, secrets, and
cost-visibility layers on top: ArgoCD with per-PR preview environments, Vault + External Secrets
Operator, and a budget + CloudWatch cost dashboard.

## Layout

```
modules/
  vpc/              public/private subnets across N AZs, NAT gateway(s)
  eks/                control plane + managed node group + OIDC/IRSA trust anchor
  rds/                 Postgres with an AWS-managed master password (Secrets Manager, never in state)
  cost-dashboard/       monthly budget + CloudWatch dashboard of estimated charges
environments/
  dev/                root module composing the above for dev (1 NAT gateway, small instances)
  prod/                same composition, prod-sized (multi-AZ NAT, Multi-AZ RDS, deletion protection)
gitops/
  argocd/               Helm values + an ApplicationSet that creates one preview environment per open PR
  apps/                  the "app of apps" Argo Application and where per-service Applications live
vault/                 Helm values for HA Vault (Raft storage, no external Consul)
external-secrets/     Helm values + example SecretStore/ExternalSecret manifests (Vault and AWS Secrets Manager)
```

## Design choices

- **RDS password**: `manage_master_user_password = true` on the `aws_db_instance` — AWS generates
  and rotates it in Secrets Manager. It never appears in Terraform state, tfvars, or this repo.
- **IRSA, not node-wide IAM**: `modules/eks` creates the IAM OIDC provider so cluster workloads
  (External Secrets Operator, in particular) can assume scoped IAM roles via their service
  account rather than inheriting whatever the EC2 node role can do.
- **Preview environments via ArgoCD's PR generator**, not a custom CI script — the ApplicationSet
  in `gitops/argocd/applicationset-preview.yaml` watches for open PRs (labeled `preview`) against
  the application repo and creates/destroys a namespaced environment automatically.
- **Cost dashboard** is a `aws_budgets_budget` (80% forecasted / 100% actual email alerts) plus a
  `aws_cloudwatch_dashboard` graphing `AWS/Billing EstimatedCharges` — both provisioned by
  Terraform alongside the infrastructure they're watching, not set up by hand in the console.

## Running this for real

This repo was built and reviewed without a connected AWS account or enough local disk space to
keep a multi-hundred-MB Terraform provider cache around (see note below) — so it's been checked
with `terraform fmt` and is designed to be syntactically and structurally correct, but has **not**
been run through `terraform validate`/`plan` against the real AWS provider locally. CI does that
on every push (see below); treat that as the first real validation pass, and review a `plan`
output carefully before ever running `apply` against an account that matters.

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars   # fill in real alert emails
cp backend.hcl.example backend.hcl             # fill in your state bucket/lock table
terraform init -backend-config=backend.hcl
terraform plan
```

### GitOps / Vault / External Secrets

These are Helm values files and Kubernetes manifests, applied after the EKS cluster exists:

```bash
aws eks update-kubeconfig --name infra-platform-dev

helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace -f gitops/argocd/values.yaml
kubectl apply -f gitops/apps/app-of-apps.yaml
kubectl apply -f gitops/argocd/applicationset-preview.yaml

helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -n vault --create-namespace -f vault/values.yaml
# then: vault operator init, vault operator unseal, enable the kubernetes auth method

helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace -f external-secrets/values.yaml
kubectl apply -f external-secrets/examples/vault-secretstore.yaml
```

## CI

`.github/workflows/terraform-ci.yml`:

- **validate**: `terraform init -backend=false && terraform validate` for every module and
  environment, matrixed.
- **fmt**: `terraform fmt -check -recursive`.
- **tflint**: static analysis with the AWS ruleset (`.tflint.hcl`).
- **plan**: a real `terraform plan` against AWS via OIDC (no stored AWS keys) — only runs if the
  repo variable `AWS_ROLE_ARN` is set, so this workflow stays green with zero AWS setup. Set that
  variable (and point it at a role trusting this repo's OIDC provider) to turn it on.

## Why the local Terraform run didn't happen here

The machine this was built on had well under 1 GB of free disk space partway through. Each
`terraform init` copies the ~690 MB `hashicorp/aws` provider into that working directory's
`.terraform/`, and Windows needs Developer Mode enabled to symlink from a shared plugin cache
instead of copying it every time — without that, validating all six module/environment
directories would have meant ~4 GB of repeated copies. Terraform and its provider cache were
removed from that machine after scaffolding this repo to reclaim the space; **CI is the first
place this configuration actually gets validated end-to-end.**
