# Contributing

Thanks for improving the landing zone. This repo favors small, reviewable,
plan-backed changes.

## Ground rules

- **Never commit** `*.tfstate*`, `*.tfvars` (only `*.tfvars.example`), or any
  credential/key file. `.gitignore` enforces this — do not override it.
- **Never run `terraform apply` against production** outside the gated CI job.
- Every change must be **`terraform fmt`-clean** and **`terraform validate`-clean**
  for all modules and environments before review.

## Module conventions

Each module under `modules/` must contain:

| File           | Purpose                                                        |
|----------------|----------------------------------------------------------------|
| `versions.tf`  | `required_version` + provider version constraints              |
| `variables.tf` | Every input typed, described, and validated where useful       |
| `main.tf`      | Resources (with comments explaining non-obvious choices)       |
| `outputs.tf`   | Everything a composing environment might need downstream       |

Conventions:

- Modules **do not** declare `provider` blocks — only `required_providers`.
  Provider configuration lives in the environment.
- Prefer `for_each` over `count` for stable, name-keyed resources.
- Add `validation` blocks to variables that have a constrained domain
  (enums, CIDRs, ID formats).
- Keep resource arguments explicit and secure-by-default; do not rely on
  provider defaults for security-relevant settings.

## How to add a new environment

1. Copy an existing environment directory, e.g. `cp -r environments/staging environments/qa`.
2. Update `backend.tf` `prefix` to `environments/qa` (state isolation).
3. Update `locals` in `main.tf`: `env`, `name_prefix`, and the subnet CIDRs
   (each environment uses a **non-overlapping** `10.1x.0.0` block).
4. Adjust `variables.tf` defaults for the environment's size and posture.
5. Provide `terraform.tfvars.example` with realistic placeholder values.
6. Add the environment to the CI plan matrix in `.github/workflows/terraform-ci.yml`.
7. Run `make validate` and `make plan ENV=qa`.

## How to add a new module

1. Create `modules/<name>/` with the four required files.
2. Wire it into each environment's `main.tf` as needed.
3. Run `make fmt validate`.

## PR / plan review process

1. Branch from `main`; make your change.
2. Run locally:
   ```bash
   make fmt validate
   make plan ENV=dev          # requires GCP auth; otherwise rely on CI
   ```
3. Open a PR. CI runs `fmt`, `validate`, `tflint`, `tfsec`, `checkov`, and a
   **non-blocking `terraform plan` per environment**.
4. Reviewers read the **plan output** in the PR checks — the plan is the unit of
   review. A change with an unexpected diff is not merged.
5. On merge to `main`, no apply happens automatically.
6. **Applies are manual**, via the `workflow_dispatch` job, and **production is
   gated** behind a protected GitHub Environment requiring reviewer approval.

## Commit style

Use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
Keep commits scoped to one logical change so plans stay reviewable.
