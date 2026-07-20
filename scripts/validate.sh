#!/usr/bin/env bash
#
# Run the full static-analysis suite across the repo. Each optional tool is
# skipped (with a notice) if it is not installed, so the script is safe to run
# locally and in CI.
#
# Usage: ./scripts/validate.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

fail=0

echo "==> terraform fmt (check, recursive)"
terraform fmt -check -recursive || { echo "  fmt issues found; run 'terraform fmt -recursive'"; fail=1; }

echo "==> terraform init + validate (every module and environment)"
for dir in modules/*/ environments/*/; do
  echo "  - ${dir}"
  (
    cd "${dir}"
    terraform init -backend=false -input=false >/dev/null
    terraform validate -no-color
  ) || fail=1
done

if command -v tflint >/dev/null 2>&1; then
  echo "==> tflint"
  tflint --recursive || fail=1
else
  echo "==> tflint not installed; skipping"
fi

if command -v tfsec >/dev/null 2>&1; then
  echo "==> tfsec"
  tfsec . || fail=1
else
  echo "==> tfsec not installed; skipping"
fi

if command -v checkov >/dev/null 2>&1; then
  echo "==> checkov (with custom policies)"
  checkov -d environments --external-checks-dir policies --quiet || fail=1
else
  echo "==> checkov not installed; skipping"
fi

if command -v conftest >/dev/null 2>&1; then
  echo "==> conftest note: run against a rendered plan JSON, e.g.:"
  echo "    terraform -chdir=environments/production plan -out=tfplan.bin"
  echo "    terraform -chdir=environments/production show -json tfplan.bin > tfplan.json"
  echo "    conftest test --policy policies tfplan.json"
else
  echo "==> conftest not installed; skipping OPA policy note"
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "VALIDATION FAILED"
  exit 1
fi
echo "VALIDATION PASSED"
