#!/usr/bin/env bash
#
# Run `terraform plan` across every environment in order (dev -> staging ->
# production). Each environment must have a terraform.tfvars (copied from the
# provided .example) or valid remote/default values.
#
# Usage:
#   ./scripts/plan-all.sh                 # uses each env's terraform.tfvars
#   BACKEND=false ./scripts/plan-all.sh   # offline: init with -backend=false
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

BACKEND="${BACKEND:-true}"
ENVIRONMENTS=(dev staging production)

for env in "${ENVIRONMENTS[@]}"; do
  dir="environments/${env}"
  echo "=================================================================="
  echo "  PLAN: ${env}"
  echo "=================================================================="

  init_args=(-input=false)
  plan_args=(-input=false -no-color)

  if [[ "${BACKEND}" == "false" ]]; then
    init_args+=(-backend=false)
  fi

  if [[ -f "${dir}/terraform.tfvars" ]]; then
    plan_args+=(-var-file=terraform.tfvars)
  else
    echo "  (no terraform.tfvars in ${dir}; relying on variable defaults / -var flags)"
  fi

  terraform -chdir="${dir}" init "${init_args[@]}" >/dev/null
  terraform -chdir="${dir}" plan "${plan_args[@]}"
done
