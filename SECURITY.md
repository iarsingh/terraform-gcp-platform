# Security

This landing zone is built to be secure by default. This document describes the
controls, the rationale behind them, and how to report a vulnerability.

## Least-privilege IAM

- **No default service accounts on nodes.** The `iam` module creates a
  dedicated GKE node service account and grants it only the minimal roles it
  needs (`logging.logWriter`, `monitoring.metricWriter`, `monitoring.viewer`,
  `stackdriver.resourceMetadata.writer`, `artifactregistry.reader`). The broad
  default compute service account is never used.
- **Workload Identity for pods.** Application pods assume Google service
  accounts via Workload Identity (`workload_metadata_config.mode =
  GKE_METADATA`). No node-level keys are shared with workloads, and no service
  account JSON keys are created.
- **IAM conditions scope secret access.** Workloads granted Secret Manager
  access receive `roles/secretmanager.secretAccessor` **conditioned** on a
  resource-name prefix, so a workload can read only its own secrets.
- **Custom deployer role.** An example custom role demonstrates curated deploy
  permissions for CI, excluding destructive project/IAM administration.

## Secrets management

- Secrets live in **Secret Manager**, never in `*.tfvars`, never in code, never
  in committed state.
- `.gitignore` blocks `*.tfvars` (except `*.tfvars.example`), all `*.tfstate*`,
  and any `*-key.json` / `*credentials*.json` so credentials cannot be committed
  accidentally.
- The Secret Manager API is enabled per project by the `project` module; grant
  access to it exclusively through Workload Identity bindings.

## Network & cluster hardening (private GKE rationale)

- **Private nodes** have no public IP addresses; the attack surface facing the
  internet is minimized. Egress is funneled through **Cloud NAT** so egress IPs
  are known and auditable.
- **Private control plane** (staging/production) removes the public API
  endpoint entirely; access is limited to `master_authorized_networks`.
- **Shielded nodes** (secure boot + integrity monitoring) defend against
  boot-/kernel-level tampering.
- **Dataplane V2** provides in-kernel (eBPF) network policy enforcement for
  pod-to-pod segmentation.
- **Deny-by-default firewall** with explicit, narrowly-scoped allow rules
  (internal, IAP SSH, health checks). Operators reach nodes via **IAP tunneling**
  rather than public SSH.

## Edge protection — Cloud Armor posture

- **Rate-based ban** throttles and temporarily bans abusive client IPs.
- **Preconfigured OWASP WAF rules** (SQLi, XSS, LFI, RCE, scanner detection).
- **Adaptive Protection** (staging/production) for Layer 7 DDoS detection.
- **Optional geo-restriction** blocks selected country codes (enabled for
  production in the example tfvars).
- **Preview vs enforce:** dev runs Cloud Armor in **preview** (log-only) so
  rules can be tuned without blocking traffic; staging and production
  **enforce**. Promoting a rule set therefore always happens after it has been
  observed in preview lower down the pipeline.

## Terraform state protection

- **Remote state in GCS** with **object versioning** enabled — every apply
  writes a new generation, so a bad apply can be rolled back to a prior state
  generation (see README → Failure/rollback).
- **Uniform bucket-level access** and **public access prevention** are set by
  `scripts/bootstrap-state-bucket.sh`; state is encrypted at rest with
  Google-managed keys (swap in CMEK if required).
- **Access control:** restrict `roles/storage.objectAdmin` on the state bucket
  to the CI service account and platform admins. Production state is recommended
  to live in a **separate bucket** so non-prod access grants nothing on prod.
- State is **never committed** to git (`.gitignore` blocks `*.tfstate*`).

## Supply chain

- **Immutable image tags** on the production Artifact Registry repository ensure
  a tag always refers to the same digest (provenance / rollback integrity).
- **Cleanup policies** delete stale untagged images to reduce exposure and cost.
- CI authenticates to GCP via **Workload Identity Federation** (OIDC), so no
  long-lived service account keys are stored in GitHub secrets.

## Policy as code

`policies/` contains OPA/Rego and custom Checkov policies enforced in CI:

- Deny GKE clusters without private nodes.
- Deny production clusters without `deletion_protection` or a private endpoint.
- Deny node pools using the default compute service account or missing
  Workload Identity metadata mode.
- Require governance labels (`env`, `managed_by`, `team`).

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue.

- Email the maintainer with a description, affected paths, and reproduction
  steps.
- Allow a reasonable disclosure window before any public discussion.
- Do not include real credentials or customer data in reports.
