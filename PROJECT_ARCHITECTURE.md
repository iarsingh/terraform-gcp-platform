# terraform-gcp-platform — project architecture

[README](README.md) · [Interview questions and answers](INTERVIEW_QA.md)

## Purpose and scope

A reusable multi-environment GCP foundation with Shared VPC, private GKE, IAM, Cloud NAT, observability, and security controls.

This document describes files and symbols in this checkout. Deployment templates and statements in the original overview are distinguished from a verified running environment.

## Component diagram

```mermaid
flowchart LR
    R["Repository"]
    R -. contains .-> C0["environments"]
    R -. contains .-> C1["modules"]
    R -. contains .-> C2["scripts"]
    R -. contains .-> C3["Makefile"]
    R -. contains .-> C4[".github"]
    R -. contains .-> C5["ARCHITECTURE.md"]
    R -. contains .-> C6["CONTRIBUTING.md"]
    R -. contains .-> C7["README.md"]
```

For Python repositories, arrows show resolved local imports, not network calls or deployment order. Otherwise the diagram is a repository component map; containment arrows do not assert runtime integration.

## Components and responsibilities

| Component | Responsibility |
| --- | --- |
| [`environments/dev/backend.tf`](environments/dev/backend.tf) | Terraform resource/module declarations |
| [`environments/dev/main.tf`](environments/dev/main.tf) | Terraform resource/module declarations |
| [`modules/artifact-registry/main.tf`](modules/artifact-registry/main.tf) | Terraform resource/module declarations |
| [`modules/artifact-registry/outputs.tf`](modules/artifact-registry/outputs.tf) | Terraform resource/module declarations |
| [`modules/artifact-registry/variables.tf`](modules/artifact-registry/variables.tf) | Terraform resource/module declarations |
| [`modules/artifact-registry/versions.tf`](modules/artifact-registry/versions.tf) | Terraform resource/module declarations |
| [`scripts/bootstrap-state-bucket.sh`](scripts/bootstrap-state-bucket.sh) | Implementation or supporting configuration |
| [`scripts/plan-all.sh`](scripts/plan-all.sh) | Implementation or supporting configuration |
| [`scripts/validate.sh`](scripts/validate.sh) | Implementation or supporting configuration |
| [`environments/dev/outputs.tf`](environments/dev/outputs.tf) | Terraform resource/module declarations |
| [`environments/dev/providers.tf`](environments/dev/providers.tf) | Terraform resource/module declarations |
| [`environments/dev/variables.tf`](environments/dev/variables.tf) | Terraform resource/module declarations |
| [`Makefile`](Makefile) | Implementation or supporting configuration |
| [`.github/workflows/terraform-ci.yml`](.github/workflows/terraform-ci.yml) | GitHub Actions job definitions |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Project explanations or operating notes |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Project explanations or operating notes |
| [`README.md`](README.md) | Project explanations or operating notes |

## Existing design and operating guides

These checked-in guides provide the project’s detailed design, operational context, or deployment view:

- [`ARCHITECTURE.md`](ARCHITECTURE.md).
- [`SECURITY.md`](SECURITY.md).

### Existing deployment/design view

The following view is retained from [`ARCHITECTURE.md`](ARCHITECTURE.md). Read that guide for its assumptions and the distinction between configured and deployed components.

```mermaid
flowchart TB
    subgraph GCP["GCP Project (one per environment)"]
        direction TB
        subgraph VPC["Shared VPC (host project)"]
            direction TB
            PUB["Public subnet<br/>10.1x.16.0/24<br/>(LBs / bastions)"]
            subgraph PRIV["Private subnet 10.1x.0.0/20"]
                direction TB
                GKE["Private GKE cluster<br/>private nodes, no public IPs<br/>Workload Identity + Dataplane V2"]
                PODS["Secondary range: pods 10.2x.0.0/16"]
                SVCS["Secondary range: services 10.3x.0.0/20"]
            end
            ROUTER["Cloud Router"]
            NAT["Cloud NAT<br/>(egress for private nodes)"]
            FW["Firewall: deny-all ingress +<br/>allow internal / IAP SSH / health checks"]
        end
        AR["Artifact Registry<br/>(Docker repos + cleanup policies)"]
        SM["Secret Manager"]
        IAMB["IAM: least-privilege node SA<br/>+ Workload Identity bindings"]
        MON["Cloud Logging / Monitoring<br/>sink + log metric + alert policies"]
        ARMOR["Cloud Armor<br/>(WAF + rate limiting)"]
    end

    INTERNET(("Internet"))
    OPS["Operators"]

    GKE -->|"images (pull)"| AR
    GKE -->|"reads secrets via WI"| SM
    GKE --> ROUTER --> NAT --> INTERNET
    INTERNET -->|"ingress LB"| ARMOR --> PUB
    OPS -->|"IAP tunnel (no public IP)"| GKE
    GKE -.->|"metrics / logs"| MON
    IAMB -.->|"binds"| GKE
```

## Infrastructure declarations

| Kind | Address | Source |
| --- | --- | --- |
| resource | `google_artifact_registry_repository.this` | [`modules/artifact-registry/main.tf`](modules/artifact-registry/main.tf) |
| resource | `google_artifact_registry_repository_iam_member.reader` | [`modules/artifact-registry/main.tf`](modules/artifact-registry/main.tf) |
| resource | `google_artifact_registry_repository_iam_member.writer` | [`modules/artifact-registry/main.tf`](modules/artifact-registry/main.tf) |
| resource | `google_compute_security_policy.this` | [`modules/cloud-armor/main.tf`](modules/cloud-armor/main.tf) |
| resource | `google_container_cluster.this` | [`modules/gke/main.tf`](modules/gke/main.tf) |
| resource | `google_container_node_pool.this` | [`modules/gke/main.tf`](modules/gke/main.tf) |
| resource | `google_service_account.gke_node` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_project_iam_member.gke_node` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_project_iam_custom_role.platform_deployer` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_service_account.workload` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_service_account_iam_member.workload_identity_user` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_project_iam_member.workload_roles` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_project_iam_member.workload_secret_accessor` | [`modules/iam/main.tf`](modules/iam/main.tf) |
| resource | `google_monitoring_notification_channel.email` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_logging_project_sink.this` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_logging_metric.container_errors` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_monitoring_alert_policy.node_cpu` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_monitoring_alert_policy.pod_restarts` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_monitoring_alert_policy.nat_port_exhaustion` | [`modules/monitoring/main.tf`](modules/monitoring/main.tf) |
| resource | `google_compute_network.this` | [`modules/network/main.tf`](modules/network/main.tf) |

These are declarations in the checkout. Provisioning, an authenticated provider, remote state, and a successful deployment are separate operational steps. Refer to the environment-specific instructions before planning changes.

## Data flow and design decisions

### Which Terraform modules compose the environment

- `module.project` uses `../../modules/project` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.network` uses `../../modules/network` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.iam` uses `../../modules/iam` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.artifact_registry` uses `../../modules/artifact-registry` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.gke` uses `../../modules/gke` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.cloud_armor` uses `../../modules/cloud-armor` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.monitoring` uses `../../modules/monitoring` in [`environments/dev/main.tf`](environments/dev/main.tf).
- `module.project` uses `../../modules/project` in [`environments/production/main.tf`](environments/production/main.tf).
- `module.network` uses `../../modules/network` in [`environments/production/main.tf`](environments/production/main.tf).
- `module.iam` uses `../../modules/iam` in [`environments/production/main.tf`](environments/production/main.tf).
- `module.artifact_registry` uses `../../modules/artifact-registry` in [`environments/production/main.tf`](environments/production/main.tf).
- `module.gke` uses `../../modules/gke` in [`environments/production/main.tf`](environments/production/main.tf).

Review each module’s variable and output contracts. Different environment declarations may reuse a module with different inputs; state and provider configuration determine the actual deployment boundary.

## Setup and verification

Follow the existing README and the component-specific instructions linked above. No new application start command is asserted for this repository.

No dedicated test files were found in the inspected first-party file inventory. A future implementation should add executable acceptance checks.

Automation definitions: [`.github/workflows/terraform-ci.yml`](.github/workflows/terraform-ci.yml). Read their triggers and job steps to determine what CI actually runs.

## Operating boundaries and design review

Before turning this checkout into a customer deployment, establish the input contract, data ownership, access controls, failure response, evaluation criteria, and rollback owner. Repository fixtures and unit tests demonstrate local behavior; they do not establish throughput, uptime, compliance, or business impact.

A useful architecture review starts with the linked implementation: identify where input enters, where a decision is made, which state can change, and which external dependency can fail. Add a deployment view only for infrastructure that is actually configured and exercised.
