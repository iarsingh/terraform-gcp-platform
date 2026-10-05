# terraform-gcp-platform — interview questions and answers

[README](README.md) · [Project architecture](PROJECT_ARCHITECTURE.md)

Answers below use this repository’s files and implementation. They distinguish existing behavior from suggested extensions; source links let you verify each walkthrough.

## 1. What problem does terraform-gcp-platform address, and what can you demonstrate?

A reusable multi-environment GCP foundation with Shared VPC, private GKE, IAM, Cloud NAT, observability, and security controls.

I would demonstrate the linked implementation or examples and distinguish that evidence from any planned production features. Start with [`README.md`](README.md).

## 2. How is this repository organized?

- [`environments/dev/backend.tf`](environments/dev/backend.tf): Terraform resource/module declarations.
- [`environments/dev/main.tf`](environments/dev/main.tf): Terraform resource/module declarations.
- [`modules/artifact-registry/main.tf`](modules/artifact-registry/main.tf): Terraform resource/module declarations.
- [`modules/artifact-registry/outputs.tf`](modules/artifact-registry/outputs.tf): Terraform resource/module declarations.
- [`modules/artifact-registry/variables.tf`](modules/artifact-registry/variables.tf): Terraform resource/module declarations.
- [`modules/artifact-registry/versions.tf`](modules/artifact-registry/versions.tf): Terraform resource/module declarations.
- [`scripts/bootstrap-state-bucket.sh`](scripts/bootstrap-state-bucket.sh): Implementation or supporting configuration.
- [`scripts/plan-all.sh`](scripts/plan-all.sh): Implementation or supporting configuration.

[PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md) contains the component diagram and the implementation walkthrough.

## 3. How would you explain the infrastructure implementation?

Begin with [`environments/dev/backend.tf`](environments/dev/backend.tf), [`environments/dev/main.tf`](environments/dev/main.tf), [`environments/dev/outputs.tf`](environments/dev/outputs.tf), [`environments/dev/providers.tf`](environments/dev/providers.tf), [`environments/dev/variables.tf`](environments/dev/variables.tf). Trace the environment inputs, module references, provider resources, and outputs. A module declaration is infrastructure intent; I would show a validated plan before claiming deployed resources.

## 4. What would you verify before extending this repository?

I would identify an executable example or define a concrete acceptance case for the material in [`README.md`](README.md). For code, verify inputs, outputs, and failure handling; for notes or templates, verify that a reader can follow the procedure and distinguish examples from measured results.

## 5. How would you verify correctness when no test suite is present?

There are no dedicated test files in the inspected first-party inventory. I would select one concrete example from [`README.md`](README.md), define expected output or an acceptance checklist, and add repeatable verification before expanding scope. For a documentation-only repository, that means checking links, instructions, and the reproducibility of examples.

## 6. How do you separate the current design from a future production design?

The current design is the source/component map in [PROJECT_ARCHITECTURE.md](PROJECT_ARCHITECTURE.md). A future deployment needs explicit input contracts, persistence decisions, authentication, monitoring, and rollback. I would present these as proposed work until the corresponding implementation and verification exist.

## 7. What would you check before applying the Terraform configuration?

I would review the selected environment, input values, provider credentials, backend/state location, module sources, and proposed plan. Begin with [`environments/dev/backend.tf`](environments/dev/backend.tf). I would not infer that a successful repository check proves the cloud resources exist or that an apply is safe.

## 8. How would another engineer reproduce your walkthrough?

Follow [`README.md`](README.md) and the linked component documents. This documentation update does not assert an application launch command for a repository without a verified launch contract.

## 9. What does automation verify, and what does it not prove?

Inspect [`.github/workflows/terraform-ci.yml`](.github/workflows/terraform-ci.yml) for triggers, permissions, and job commands. I would name the checks that those definitions run and show the latest run separately. A workflow definition alone does not establish a successful deployment, security review, or production SLO.

## 10. How would you present this project in a Forward Deployed Engineer interview?

Start with the user and operational problem described in [`README.md`](README.md). Explain one constraint that changes the implementation, show the linked code or example, and walk through a success case and a failure case. Agree on a measurable acceptance criterion before expanding the solution, and leave a handoff with data boundaries and rollback ownership. Any proposed production or business metric should be identified as a target until measured.

## 11. Which Terraform modules compose the environment?

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
